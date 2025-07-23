"""
Ansible lint rule: Avoid setting sensitive values directly to Kubernetes pods via environment variables.

Prevents two key issues:
1. Kubernetes environment variable interpolation can mangle passwords with special characters
   See: https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/
2. Passwords should be stored in Kubernetes secrets as a best practice
"""

import re
from typing import TYPE_CHECKING
from ansiblelint.rules import AnsibleLintRule

if TYPE_CHECKING:
    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task


class KubernetesPasswordEnvRule(AnsibleLintRule):
    """Avoid setting sensitive values directly to Kubernetes pods via environment variables."""

    id = "k8s-password-env"
    shortdesc = "Avoid setting sensitive values directly to Kubernetes pods via environment variables"
    description = (
        "Avoid setting sensitive values directly to Kubernetes pods via environment variables "
        "to prevent interpolation issues and follow best practices. "
        "Use secrets instead, such as using valueFrom: secretKeyRef."
    )
    severity = "HIGH"
    tags = ["security", "kubernetes"]
    version_added = "1.0.0"
    version_changed = "1.0.0"

    sensitive_vars = re.compile(r'(password|secret|token|key|auth|pass|pwd)', re.IGNORECASE)

    def matchtask(self, task: "Task", file: "Lintable | None" = None) -> bool | str:
        # Only check k8s tasks
        if task.get("action", {}).get("__ansible_module__") != "kubernetes.core.k8s":
            return False

        # Find violations in all containers
        violations = []
        for container in self._get_containers(task):
            for env in container.get("env", []):
                if (self.sensitive_vars.search(env.get("name", "")) and 
                    "value" in env and "valueFrom" not in env):
                    violations.append(env["name"])

        if violations:
            vars_str = "', '".join(violations)
            return (
                f"Avoid setting sensitive values '{vars_str}' directly to Kubernetes pods "
                f"via environment variables to prevent interpolation issues and follow best practices. "
                f"Use secrets instead using 'valueFrom: secretKeyRef:'"
            )

        return False

    def _get_containers(self, task):
        """Extract all containers from k8s definition."""
        spec = task.get("action", {}).get("definition", {}).get("spec", {})
        if "template" in spec:  # Deployment/ReplicaSet
            spec = spec["template"]["spec"]
        return spec.get("containers", []) + spec.get("initContainers", [])
