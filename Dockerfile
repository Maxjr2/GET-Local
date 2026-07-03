FROM python:3.12-slim-trixie AS python-build

ARG install_python_latest_pkgs=false

COPY ansible /gitlab-environment-toolkit/ansible
COPY terraform /gitlab-environment-toolkit/terraform
COPY .tool-versions /gitlab-environment-toolkit/.tool-versions
COPY ./bin/docker/setup-get-symlinks.sh /gitlab-environment-toolkit/bin/setup-get-symlinks.sh

USER root
WORKDIR /gitlab-environment-toolkit
SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.local/bin:$PATH"

RUN apt-get update -y && apt-get install -y --no-install-recommends build-essential libssl-dev uuid-dev cmake libcurl4-openssl-dev pkg-config git curl unzip && rm -rf /var/lib/apt/lists/*

# Install Ansible
## Install Python Packages (Including Ansible)
RUN pip3 install --no-cache-dir --user -r $(if [[ "$install_python_latest_pkgs" == "true" ]]; then echo "ansible/requirements/ansible-python-packages.txt"; else echo "ansible/requirements/requirements.txt"; fi)
## Install Ansible Dependencies
RUN ansible-galaxy install -r ansible/requirements/ansible-galaxy-requirements.yml

#####

FROM python:3.12-slim-trixie

COPY --from=python-build /root/ /root/
COPY --from=python-build /gitlab-environment-toolkit /gitlab-environment-toolkit

USER root
WORKDIR /gitlab-environment-toolkit
SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:$PATH"

RUN source ~/.bashrc && apt-get update -y && apt-get install --no-install-recommends -y curl unzip nano git-crypt gnupg openssh-client lsb-release && rm -rf /var/lib/apt/lists/*

# Install Mise
RUN curl https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /usr/share/keyrings/mise-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt-get update && apt-get install -y --no-install-recommends mise && rm -rf /var/lib/apt/lists/*

# Add Terraform plugin (via Mise)
RUN mise plugins install terraform -y

# Install cloud/k8s tools
### kubectl / helm - used for Cloud Native Hybrid (bring-your-own Kubernetes cluster, e.g. on-prem or self-managed)
RUN apt-get install -y --no-install-recommends kubectl && rm -rf /var/lib/apt/lists/*
RUN curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Configure environment on login
RUN echo -e '\n. /gitlab-environment-toolkit/bin/setup-get-symlinks.sh' >> ~/.bashrc && \
    echo -e '\neval "$(mise activate bash)"' >> ~/.bashrc

RUN mkdir -p /gitlab-environment-toolkit/keys && mkdir /environments

CMD ["bash"]
