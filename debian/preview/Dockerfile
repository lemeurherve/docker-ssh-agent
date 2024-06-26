ARG DEBIAN_RELEASE=bookworm-20230904
FROM debian:"${DEBIAN_RELEASE}" AS jre-build
ARG JAVA_VERSION=21.0.1+12
# This Build ARG is populated by Docker
# Ref. https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETPLATFORM

SHELL ["/bin/bash","-e", "-u", "-o", "pipefail", "-c"]

RUN apt-get update \
  && apt-get install --no-install-recommends -y ca-certificates curl jq \
  && ARCH=$(uname -m | sed -e 's/x86_64/x64/' -e 's/armv7l/arm/') \
  && JAVA_VERSION_ENCODED=$(printf '%s' "$JAVA_VERSION" | jq -jRr '@uri') \
  && BUILD_NUMBER=$(printf '%s' "$JAVA_VERSION" | cut -d'+' -f2) \
  && JAVA_MAJOR_VERSION=$(printf '%s' "$JAVA_VERSION" | cut -d'.' -f1) \
  && JAVA_VERSION_KEBAB=$(printf '%s' "$JAVA_VERSION" | sed 's/+/-/g;s/\./-/g') \
  && curl -sL https://github.com/adoptium/temurin"${JAVA_MAJOR_VERSION}"-binaries/releases/download/jdk-"${JAVA_VERSION_ENCODED}"-ea-beta/OpenJDK"${JAVA_MAJOR_VERSION}"U-jdk_"${ARCH}"_linux_hotspot_ea_"${JAVA_VERSION_KEBAB}".tar.gz | tar xz -C /opt/ \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/jdk-${JAVA_VERSION}/bin:${PATH}"

# It is acceptable to have a larger image in arm/v7 (arm 32 bits) environment.
# Because jlink fails with the error "jmods: Value too large for defined data type" error.
RUN cp -r "/opt/jdk-${JAVA_VERSION}" /javaruntime

FROM debian:"${DEBIAN_RELEASE}"

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}

ENV JENKINS_AGENT_HOME=${JENKINS_AGENT_HOME}
ARG AGENT_WORKDIR="${JENKINS_AGENT_HOME}/agent"
# Persist agent workdir path through an environment variable for people extending the image
ENV AGENT_WORKDIR=${AGENT_WORKDIR}

RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}" \
    # Prepare subdirectories
    && mkdir -p "${JENKINS_AGENT_HOME}/.ssh/" "${AGENT_WORKDIR}" "${JENKINS_AGENT_HOME}/.jenkins" \
    # Make sure that user 'jenkins' own these directories and their content
    && chown -R "${uid}":"${gid}" "${JENKINS_AGENT_HOME}" "${AGENT_WORKDIR}"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        git-lfs \
        less \
        netcat-traditional \
        openssh-server \
        patch \
    && rm -rf /var/lib/apt/lists/*

# setup SSH server
RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd

# VOLUME directive must happen after setting up permissions and content
VOLUME "${AGENT_WORKDIR}" "${JENKINS_AGENT_HOME}"/.jenkins "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

ENV LANG='C.UTF-8' LC_ALL='C.UTF-8'

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
COPY --from=jre-build /javaruntime $JAVA_HOME

RUN echo "PATH=${PATH}" >> /etc/environment
COPY setup-sshd /usr/local/bin/setup-sshd

EXPOSE 22

ENTRYPOINT ["setup-sshd"]

LABEL \
    org.opencontainers.image.vendor="Jenkins project" \
    org.opencontainers.image.title="Official Jenkins SSH Agent Docker image" \
    org.opencontainers.image.description="A Jenkins agent image which allows using SSH to establish the connection" \
    org.opencontainers.image.url="https://www.jenkins.io/" \
    org.opencontainers.image.source="https://github.com/jenkinsci/docker-ssh-agent" \
    org.opencontainers.image.licenses="MIT"
