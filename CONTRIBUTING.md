# Contributing

Thank you for your interest in contributing to the GitLab Environment Toolkit! We welcome
all contributions. By participating in this project, you agree to abide by the
[Code of Conduct](#code-of-conduct).

## Contributor License Agreement

Contributions to this repository are subject to the Individual or Corporate Contributor License Agreement, depending on whose behalf a contribution is made:

- By submitting code contributions as an individual to this repository, you agree to the [Individual Contributor License Agreement](https://docs.gitlab.com/ee/legal/individual_contributor_license_agreement.html).
- By submitting code contributions on behalf of a corporation to this repository, you agree to the [Corporate Contributor License Agreement](https://docs.gitlab.com/ee/legal/corporate_contributor_license_agreement.html).

## Areas for contributions

The GitLab Environment Toolkit is designed as a toolkit for a wide range of users and touches on a lot of areas including Terraform, Ansible, GitLab, Cloud Providers, Networking and more.

As such, making changes or adding features are typically more complex than one may expect and need to be considered
against [the wider picture that the Toolkit is designed for](#technical-design). This is especially so for new features, which will typically require
scheduled development time from the maintainers regardless to ensure the feature is correct and follows the design.

Additionally, maintenance areas such as plugin / package versions, code design rules or linter config are reserved for the maintainer group to handle although if there is an issue in one of these areas do raise an issue for the group to investigate.

As a general guidance, contributions should typically only be for extending existing features.

If you are thinking of contributing, we recommended you first check our open issues to see if there is any for that area. Please ask in the issue selected or raise a new issue accordingly to talk through the design with the team first before contributing.

## Technical Design

Before contributing you should read and acknowledge our [Technical Design](TECHNICAL_DESIGN.md) document in full.

## Merge requests

We welcome merge requests with fixes and improvements to GitLab Environment Toolkit code and/or documentation. 
The issues that are specifically suitable for community contributions are listed with the label
[`Accepting Merge Requests` on our issue tracker](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/work_items?label_name%5B%5D=Accepting+merge+requests), but you are
free to contribute to any other issue you want.

Please note that if an issue is marked for the current milestone either before
or while you are working on it, a team member may take over the merge request
in order to ensure the work is finished before the release date.

If you want to add a new feature that is not labelled it is best to first create
a feedback issue (if there isn't one already) and leave a comment asking for it
to be marked as `Accepting Merge Requests`.

Merge requests should be opened [on this project](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/merge_requests).

### Merge request guidelines

Merge Requests should follow our value of [Iteration](https://about.gitlab.com/handbook/values/#iteration). In particular, **[MRs should be small and focused](https://about.gitlab.com/handbook/values/#make-small-merge-requests)** for the specific targetted area.

#### Merge Request Workflow

GitLab Environment Toolkit team uses the [Reviewers feature](https://docs.gitlab.com/ee/development/code_review.html#dogfooding-the-reviewers-feature) in the code review process. The process looks like this:

1. Author opens a merge request in a project. Label ~"workflow::in dev" is applied by default.
1. When ready for review, the Author applies the ~"workflow::ready for review" label and mentions `@gitlab-org/software-delivery/get-maintainers`.
1. When they are able to work on the merge request, a Maintainer adds themselves under the Reviewers section, and adds the ~"workflow::in review" label.
1. The Maintainer works with the Author to get the merge request to a state where they approve it.
    - The Maintainer could apply ~"workflow::in dev" to the merge request if there are additional changes that need to be done by the Author. When the merge request is ready to be handed back for further review, Author should apply ~"workflow::ready for review" label and mention the Maintainer who previously reviewed the merge request.

**NOTE**: If you are working on a merge request that requires a response quicker than the [First-response SLO](https://about.gitlab.com/handbook/engineering/workflow/code-review/#first-response-slo), please `@` mention the `gitlab-org/software-delivery/get-maintainers` group in order to alert the team.

##### Merge Request Workflow labels

Labels help to provide a high-level overview for the merge request state. We use the following labels:

- ~"workflow::in dev": work on merge request is in progress
- ~"workflow::ready for review": merge request is ready for review
- ~"workflow::in review": merge request is in the process of being reviewed by maintainers
- ~"breaking change": merge request adds a breaking change

###### Assigning Merge Requests

We recommend contributors to **not** assign merge requests to an individual when looking for the review, unless there is a specific reason someone should look at a merge request. Rather, the merge request should have the ~"workflow::ready for review" label applied, and a reviewer will add themselves under the Reviewers' section when they are beginning to look into it. When looking for a merge request to work on, consider the [First-response SLO](https://about.gitlab.com/handbook/engineering/workflow/code-review/#first-response-slo). Anything in danger of breaching that deadline should be looked at first.

## Code of Conduct

As contributors and maintainers of this project, we pledge to respect all people
who contribute through reporting issues, posting feature requests, updating
documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free
experience for everyone, regardless of level of experience, gender, gender
identity and expression, sexual orientation, disability, personal appearance,
body size, race, ethnicity, age, or religion.

Examples of unacceptable behaviour by participants include the use of sexual
language or imagery, derogatory comments or personal attacks, trolling, public
or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject
comments, commits, code, wiki edits, issues, and other contributions that are
not aligned to this Code of Conduct. Project maintainers who do not follow the
Code of Conduct may be removed from the project team.

This code of conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community.

Instances of abusive, harassing, or otherwise unacceptable behaviour can be
reported by emailing contact@gitlab.com.

This Code of Conduct is adapted from the [Contributor Covenant](https://contributor-covenant.org), version 1.1.0,
available at [https://contributor-covenant.org/version/1/1/0/](https://contributor-covenant.org/version/1/1/0/).
