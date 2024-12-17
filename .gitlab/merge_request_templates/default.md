<!--
# README first!

The Toolkit has a nuanced and layered design that [integrates with numerous tools and services](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/TECHNICAL_DESIGN.md#integrations-list). As such, it's _strongly recommended_ that you raise an issue first to discuss the best way to tackle the problem that works with the Toolkit's and dependent tool and service designs.

Any contributions to the Toolkit _must_ follow our [Contributing](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/CONTRIBUTING.md) and [Technical Design](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/TECHNICAL_DESIGN.md) guides. Changes should not go against [what the Toolkit isn't for](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/TECHNICAL_DESIGN.md#what-is-it-not) as well as follow our [Focused Design](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/TECHNICAL_DESIGN.md#focused-design) principals.

We aim to review all MRs within 2 weeks although generally it's much quicker than this. If there's been no response please ping the @gitlab-org/software-delivery/get-maintainers group.
-->

## What does this MR do?

<!-- Briefly describe what this MR is about. -->


<!-- Set the appropriate milestone -->
/milestone %

<!-- Set Work Type and Subtype Classification label(s) for the MR - https://about.gitlab.com/handbook/engineering/metrics/#work-type-classification -->
<!-- Note: Only one subtype should be selected -->
/label ~type::
/label ~bug:: ~feature:: ~maintenance::

<!-- Set Workflow label for the MR - https://about.gitlab.com/handbook/engineering/workflow/#basics -->
/label ~workflow::

## Related issues

<!-- There should always be a corresponding issue raised and reviewed by the GET maintainers team -->
<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Author's checklist

When ready for review, the Author applies the ~"workflow::ready for review" label and mention `@gitlab-org/software-delivery/get-maintainers`:

- Merge request:
  - [ ] Corresponding Issue raised and reviewed by the GET maintainers team.
  - [ ] Merge Request Title and Description are up-to-date, accurate, and descriptive
  - [ ] MR targeting the appropriate branch
  - [ ] MR has a green pipeline
  - [ ] MR has no new security alerts in the widget from the `Secret Detection` and `IaC Scan (SAST)` jobs.
- Code:
  - [ ] Check the area changed works as expected. Consider testing it in different environment sizes (1k,3k,10k,etc.).
  - [ ] Documentation created/updated in the same MR.
  - [ ] If this MR adds an optional configuration - check that all permutations continue to work.
  - [ ] For Terraform changes: set up a previous version environment, then run a `terraform plan` with your new changes and ensure nothing will be destroyed. If anything will be destroyed and this can't be avoided please add a comment to the current MR.
- [ ] Create any follow-up issue(s) to support the new feature across other supported cloud providers or advanced configurations. Create 1 issue for each provider/configuration. Contact the [Self-Managed Platform](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/self-managed-platform-team/) team if unsure.

/label ~"section::platforms"
