FROM python:slim-bullseye as python-build

COPY ansible /gitlab-environment-toolkit/ansible
COPY terraform /gitlab-environment-toolkit/terraform
COPY .tool-versions /gitlab-environment-toolkit/.tool-versions
COPY ./bin/docker/setup-get-symlinks.sh /gitlab-environment-toolkit/bin/setup-get-symlinks.sh

USER root
WORKDIR /gitlab-environment-toolkit
SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.asdf/shims:/root/.asdf/bin:/root/.local/bin:$PATH"

RUN apt-get update -y && apt-get install -y --no-install-recommends build-essential git curl jq unzip && rm -rf /var/lib/apt/lists/*

# Install ASDF
RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git /root/.asdf && \
    echo -e '\n. /root/.asdf/asdf.sh' >> ~/.bashrc && \
    echo -e '\n. /root/.asdf/asdf.sh' >> ~/.profile && \
    source ~/.bashrc

# Install Terraform
RUN asdf plugin add terraform && \
    asdf install terraform

# Install Ansible
## Install Python Packages (Including Ansible)
RUN pip3 install --no-cache-dir --user -r ansible/requirements/requirements.txt
## Install Ansible Dependencies
RUN /root/.local/bin/ansible-galaxy install -r ansible/requirements/ansible-galaxy-requirements.yml

#####

FROM python:slim-bullseye

COPY --from=python-build /root/ /root/
COPY --from=python-build /gitlab-environment-toolkit /gitlab-environment-toolkit

USER root
WORKDIR /gitlab-environment-toolkit
SHELL ["/bin/bash", "-c"]

ENV PATH="/root/.asdf/shims:/root/.asdf/bin:/root/.local/bin:$PATH"
ENV GCP_AUTH_KIND="application"
ENV USE_GKE_GCLOUD_AUTH_PLUGIN="True"

RUN source ~/.bashrc && apt-get update -y && apt-get install --no-install-recommends -y curl unzip git-crypt gnupg openssh-client lsb-release && rm -rf /var/lib/apt/lists/*

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

# Copy Environments on login
RUN echo -e '\n. /gitlab-environment-toolkit/bin/setup-get-symlinks.sh' >> ~/.bashrc && \
    echo -e '\n export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc

RUN mkdir -p /gitlab-environment-toolkit/keys && \
    mkdir /environments

CMD ["bash"]
