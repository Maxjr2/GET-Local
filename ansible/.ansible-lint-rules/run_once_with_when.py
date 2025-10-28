"""
Ansible lint rule: Avoid using run_once with when conditions that filter hosts.

Prevents silent task skipping when run_once is combined with host-filtering when
conditions. When a task or block has both run_once and a when condition that filters
by host-specific criteria (like group_names), the task may be silently skipped entirely.

run_once attempts to execute on the first host in the play. If that first host doesn't
match the when condition (e.g., not in the target group), the task is skipped. Since
run_once already attempted execution (even though it was skipped), it won't retry on
subsequent hosts that DO match the condition. The task never runs on any host, causing
silent failures and undefined registered variables.

The behavior depends on inventory order: if matching hosts happen to be first, it works.
If non-matching hosts are first, it silently fails. This inconsistency makes the code
fragile and difficult to debug.

See: https://github.com/ansible/ansible/issues/41895
"""

import re
from typing import TYPE_CHECKING, Any
from ansiblelint.rules import AnsibleLintRule
from ansiblelint.file_utils import Lintable

if TYPE_CHECKING:
    from ansiblelint.utils import Task


class RunOnceWithWhenRule(AnsibleLintRule):
    """Avoid using run_once with when conditions that filter hosts."""

    id = "run-once-with-when"
    shortdesc = "Avoid using run_once with when conditions that filter hosts"
    description = (
        "Using run_once with a host-filtering when condition causes tasks to be "
        "silently skipped. The when condition filters which hosts should run the task, "
        "but run_once executes on the first host in the play's order, not the first matching host. "
        "If the first host doesn't match the filter, the task is skipped and won't retry on "
        "matching hosts, causing it to never execute. This inventory-order-dependent behavior causes "
        "silent failures and undefined registered variables. Consider removing run_once or moving "
        "the task outside the conditional block."
    )
    severity = "MEDIUM"
    tags = ["reliability", "idempotency"]
    version_changed = "1.0.0"

    # Patterns that indicate host-filtering conditions (vary per host)
    host_filtering_patterns = [
        r'\bgroup_names\b',                    # 'postgres' in group_names - varies per host
        r'\binventory_hostname\b',             # inventory_hostname == 'host1' - varies per host
        r'\bansible_hostname\b',               # ansible_hostname == 'host1' - varies per host
        r'\bansible_fqdn\b',                   # ansible_fqdn contains 'prod' - varies per host
        r'\bansible_play_hosts\b',             # inventory_hostname in ansible_play_hosts - varies per host
        r'\bansible_play_batch\b',             # inventory_hostname in ansible_play_batch - varies per host
    ]
    
    # Patterns that check groups but DON'T filter hosts (same for all hosts)
    # These should NOT trigger the rule
    non_filtering_groups_patterns = [
        r'groups\[.*\]\s*\|\s*length',         # groups['postgres'] | length > 1
        r'groups\[.*\]\s*is\s+defined',        # groups['redis'] is defined
        r'groups\[.*\]\s*is\s+not\s+defined',  # groups['redis'] is not defined
        r'groups\.get\(',                       # groups.get('postgres', [])
    ]

    def matchtask(self, task: "Task", file: "Lintable | None" = None) -> bool | str:
        """Check if task uses run_once with host-filtering when condition."""
        # Check if task has run_once
        if not task.get("run_once"):
            return False

        # Skip if task is safely delegating with delegate_facts
        if task.get("delegate_to") and task.get("delegate_facts"):
            return False

        # Skip if task delegates to localhost
        delegate_to = task.get("delegate_to", "")
        if delegate_to in ["localhost", "127.0.0.1", "::1"]:
            return False
        
        # Skip if task uses delegate_to with a loop (with_*, loop)
        # This pattern delegates to multiple hosts so run_once doesn't skip hosts
        if task.get("delegate_to") and self._has_loop(task):
            return False

        # Check if task itself has host-filtering when condition
        if "when" in task:
            when_str = self._when_to_string(task["when"])
            
            # Skip hostvars['localhost'] checks
            if "hostvars['localhost']" in when_str or 'hostvars["localhost"]' in when_str:
                return False
                
            if self._is_host_filtering_condition(when_str):
                return (
                    "Task uses 'run_once' with a host-filtering 'when' condition. "
                    "If the first host in inventory order doesn't match the condition, "
                    "the task is skipped and won't retry on matching hosts, causing it "
                    "to never execute. Consider removing 'run_once' or adjusting the 'when' condition."
                )

        # Check if task is in a block with host-filtering when
        if file and hasattr(file, 'data'):
            block_when = self._find_parent_block_when(task, file.data)
            if block_when:
                when_str = self._when_to_string(block_when)
                
                # Skip hostvars['localhost'] checks
                if "hostvars['localhost']" in when_str or 'hostvars["localhost"]' in when_str:
                    return False
                    
                if self._is_host_filtering_condition(when_str):
                    task_name = task.get("name", "unnamed task")
                    return (
                        f"Task '{task_name}' uses 'run_once' inside a block with a "
                        f"host-filtering 'when' condition. If the first host in inventory "
                        f"order doesn't match the condition, the task is skipped and won't "
                        f"retry on matching hosts, causing it to never execute. "
                        f"Consider removing 'run_once' or moving the task outside the conditional block."
                    )

        return False

    def _has_loop(self, task: "Task") -> bool:
        """Check if task has any loop construct."""
        loop_keywords = [
            "loop", "with_items", "with_list", "with_dict", "with_fileglob",
            "with_filetree", "with_together", "with_sequence", "with_subelements",
            "with_nested", "with_random_choice", "with_first_found", 
            "with_indexed_items", "with_flattened", "with_inventory_hostnames"
        ]
        return any(task.get(keyword) for keyword in loop_keywords)

    def _find_parent_block_when(self, task: "Task", data: Any) -> Any:
        """Find when condition from parent block by searching the file data."""
        task_name = task.get("name")
        if not task_name:
            return None
        
        # Get the line number to help find the right task if names aren't unique
        task_line = task.get("__line__", -1)
            
        # Search through the data structure
        return self._search_in_data(task_name, task_line, data)

    def _search_in_data(self, task_name: str, task_line: int, data: Any, current_block_when: Any = None) -> Any:
        """Recursively search data structure for task and track block when conditions."""
        if isinstance(data, dict):
            # If this is a block, remember its when condition
            if "block" in data:
                block_when = data.get("when")
                # Search within the block
                for task in data.get("block", []):
                    result = self._search_in_data(task_name, task_line, task, block_when)
                    if result is not None:
                        return result
                # Also check rescue and always sections
                for section in ["rescue", "always"]:
                    for task in data.get(section, []):
                        result = self._search_in_data(task_name, task_line, task, block_when)
                        if result is not None:
                            return result
            
            # Check if this task matches what we're looking for
            if data.get("name") == task_name:
                # If we have line numbers, verify they match
                if task_line >= 0 and data.get("__line__", -2) == task_line:
                    return current_block_when
                # If no line numbers available, just match by name
                elif task_line < 0:
                    return current_block_when
            
            # Recursively search other dict values
            for key, value in data.items():
                if key not in ["block", "rescue", "always"]:  # Already handled above
                    result = self._search_in_data(task_name, task_line, value, current_block_when)
                    if result is not None:
                        return result
                        
        elif isinstance(data, list):
            for item in data:
                result = self._search_in_data(task_name, task_line, item, current_block_when)
                if result is not None:
                    return result
        
        return None

    def _is_host_filtering_condition(self, when_str: str) -> bool:
        """Check if when condition contains host-filtering criteria."""
        # First, check if it's a non-filtering groups pattern (safe usage)
        for pattern in self.non_filtering_groups_patterns:
            if re.search(pattern, when_str):
                return False
        
        # Now check for host-filtering patterns
        for pattern in self.host_filtering_patterns:
            if re.search(pattern, when_str):
                return True

        return False

    def _when_to_string(self, when_value) -> str:
        """Convert when value to string for pattern matching."""
        if isinstance(when_value, list):
            return " ".join(str(item) for item in when_value)
        return str(when_value)