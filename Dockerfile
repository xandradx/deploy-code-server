# Start from the code-server Debian base image
FROM codercom/code-server:4.18.0-ubuntu

USER root

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash \
  MAVEN_PATH=/opt/maven \
  GRADLE_PATH=/opt/gradle
ARG MAVEN_VERSION=3.9.5 \
  GRADLE_VERSION=8.4

# Install unzip + rclone (support for remote filesystem)
RUN export DEBIAN_FRONTEND=noninteractive && \
  curl -LO https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb  && \
  dpkg -i packages-microsoft-prod.deb && \
  rm packages-microsoft-prod.deb && \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install unzip dotnet-sdk-7.0 openjdk-17-jdk -y && \
  SUDO_FORCE_REMOVE=yes apt-get purge -y sudo && \
  mkdir -p ${MAVEN_PATH} && \
  mkdir -p ${GRADLE_PATH} && \
  curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  chmod 755 /usr/local/bin/kubectl && \
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
  chmod 700 /tmp/get_helm.sh && \
  /tmp/get_helm.sh && \
  curl -LO https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
  tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz --strip-components=1 -C ${MAVEN_PATH}  && \
  rm apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
  curl -LO https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
  unzip gradle-${GRADLE_VERSION}-bin.zip && \
  mv gradle-${GRADLE_VERSION}/* ${GRADLE_PATH} && \
  rm -Rf gradle-${GRADLE_VERSION} gradle-${GRADLE_VERSION}-bin.zip && \
  rm /tmp/get_helm.sh && \
  apt-get clean autoclean && \
  apt-get autoremove --yes && \
  rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
  echo "export PATH=\$PATH:${MAVEN_PATH}/bin" >> /etc/profile.d/custom-tools.sh && \
  echo "export PATH=\$PATH:${GRADLE_PATH}/bin" >> /etc/profile.d/custom-tools.sh


#RUN curl https://rclone.org/install.sh | sudo bash

# Copy rclone tasks to /tmp, to potentially be used
#COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Fix permissions for code-server
RUN chown -R coder:coder /home/coder

# You can add custom software and dependencies for your environment below
# -----------

USER coder

# Install a VS Code extension:
# Note: we use a different marketplace than VS Code. See https://github.com/cdr/code-server/blob/main/docs/FAQ.md#differences-compared-to-vs-code
RUN code-server --install-extension redhat.vscode-quarkus --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

# Install apt packages:
# RUN sudo apt-get install -y ubuntu-make

# Copy files: 
# COPY deploy-container/myTool /home/coder/myTool

# -----------

# Port
ENV PORT=8080

# Use our custom entrypoint script first
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
