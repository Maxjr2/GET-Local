FROM python:3.11-slim-bullseye as python-build

ARG install_python_latest_pkgs=false

COPY ansible /gitlab-environment-toolkit/ansible
COPY terraform /gitlab-environment-toolkit/terraform
COPY .tool-versions /gitlab-environment-toolkit/.tool-versions
COPY ./bin/docker/setup-get-symlinks.sh /gitlab-environment-toolkit/bin/setup-get-symlinks.sh

USER root
WORKDIR /gitlab-environment-toolkit
SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.local/share/rtx/bin:/root/.local/share/rtx/shims:/root/.local/bin:$PATH"

RUN apt-get update -y && apt-get install -y --no-install-recommends build-essential libssl-dev uuid-dev cmake libcurl4-openssl-dev pkg-config git curl jq unzip && rm -rf /var/lib/apt/lists/*

# Install RTX
RUN mkdir -p /root/.local/share/rtx/bin && \
    curl https://rtx.pub/rtx-latest-linux-$(dpkg --print-architecture) > /root/.local/share/rtx/bin/rtx && \
    chmod +x /root/.local/share/rtx/bin/rtx 

# Install Terraform (via RTX)
RUN rtx plugin add terraform && rtx install terraform

# Install Ansible
## Install Python Packages (Including Ansible)
RUN pip3 install --no-cache-dir --user -r $(if [[ "$install_python_latest_pkgs" == "true" ]]; then echo "ansible/requirements/ansible-python-packages.txt"; else echo "ansible/requirements/requirements.txt"; fi)
## Install Ansible Dependencies
RUN ansible-galaxy install -r ansible/requirements/ansible-galaxy-requirements.yml

#####

FROM python:3.11-slim-bullseye

COPY --from=python-build /root/ /root/
COPY --from=python-build /gitlab-environment-toolkit /gitlab-environment-toolkit

USER root
WORKDIR /gitlab-environment-toolkit
SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.local/share/rtx/bin:/root/.local/share/rtx/shims:/root/.local/bin:$PATH"

ENV GCP_AUTH_KIND="application"
ENV USE_GKE_GCLOUD_AUTH_PLUGIN="True"

RUN source ~/.bashrc && apt-get update -y && apt-get install --no-install-recommends -y curl unzip nano git-crypt gnupg openssh-client lsb-release && rm -rf /var/lib/apt/lists/*

# Install cloud tools
## gcloud cli
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk-$(lsb_release -c -s) main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y --no-install-recommends google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin && rm -rf /var/lib/apt/lists/*
## aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws
### azure cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
### kubectl / helm
RUN apt-get install -y --no-install-recommends kubectl && rm -rf /var/lib/apt/lists/*
RUN curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Configure environment on login
RUN echo -e '\n. /gitlab-environment-toolkit/bin/setup-get-symlinks.sh' >> ~/.bashrc && \
    echo -e '\neval "$(rtx activate bash)"' >> ~/.bashrc

RUN mkdir -p /gitlab-environment-toolkit/keys && mkdir /environments

CMD ["bash"]
