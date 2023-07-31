ARG IMAGE_NAME
ARG IMAGE_TAG
ARG RHEL_VERSION
ARG REPOSITORY_URL
ARG NB_USER=nobody
ARG NB_HOME=/home/${NB_USER}
ARG NB_UID=1001
FROM jupyterhub/configurable-http-proxy:4.5.3 as base
FROM redhat/ubi9:latest as build

# use bash as the default shell for this image
SHELL ["/bin/bash", "-l", "-c"]

# jovyan user details
ARG NB_USER
ARG NB_UID
ARG NB_HOME

# Update yum repository list
ARG UBI_FILE

# RUN rm -f /etc/yum.repos.d/bsk-rhel*-main.repo && \
#     rm -f /etc/yum.repos.d/bsk-rhel*-main-epel-everything.repo && \
#     rm -f /etc/yum.repos.d/bsk-ubi*.repo
# COPY ${UBI_FILE} /etc/yum.repos.d/ubi.repo

ARG INSTALL_DIR=srv/configurable-http-proxy
ARG APP_INSTALL_DIR=${NB_HOME}/${INSTALL_DIR}

USER root

# RUN dnf install npm -y --nodocs && \
# RUN dnf module install nodejs:18/common -y --nodocs && \
RUN dnf upgrade -y --nodocs && \
    dnf install git -y --nodocs && \
    dnf clean all && \
    rm -rf /var/cache/dnf && \
    mkdir -p ${APP_INSTALL_DIR} && \
    mkdir -p /tmp/packages

# Install nvm
# Instructions:
#   https://github.com/nvm-sh/nvm/issues/1533
#   https://github.com/nvm-sh/nvm#git-install
ENV NVM_DIR=/opt/.nvm
ENV NVM_PROFILE=/etc/profile.d/nvm.sh

RUN groupadd nvm && \
    usermod -aG nvm root && \
    mkdir ${NVM_DIR} && \
    chown :nvm ${NVM_DIR} && \
    chmod g+ws ${NVM_DIR}

WORKDIR ${NVM_DIR}
RUN git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" && \
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

RUN mkdir ${NVM_DIR}/.cache && \
    mkdir ${NVM_DIR}/versions && \
    mkdir ${NVM_DIR}/alias && \
    chmod -R g+ws ${NVM_DIR}/.cache && \
    chmod -R g+ws ${NVM_DIR}/versions && \
    chmod -R g+ws ${NVM_DIR}/alias

RUN echo 'export NVM_DIR="/opt/.nvm"' > ${NVM_PROFILE} && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >${NVM_PROFILE} && \
    chmod +x ${NVM_PROFILE}

# Install newest nodejs using nvm, set it as default.
RUN nvm install node && \
    nvm alias default node

# create appown user and group && \
RUN dnf install -y --nodocs shadow-utils
    # groupadd ${NB_USER} --gid ${NB_UID} && \
    # useradd -u ${NB_UID} -d ${NB_HOME} -s /sbin/nologin -c "Appown user" -g ${NB_UID} ${NB_USER} && \

RUN chage -M 99999 ${NB_USER} && \
    chown ${NB_USER}:root /home/${NB_USER} && \
    chmod 750 /home/${NB_USER} && \
    mkdir /home/${NB_USER}/tmp && \
    chmod 770 /home/${NB_USER}/tmp

# add appown user to nvm group
RUN usermod --append --groups nvm $NB_USER

# Copy relevant files from base image
COPY --from=base --chown=$NB_USER:root ${INSTALL_DIR} ${APP_INSTALL_DIR}/
WORKDIR ${APP_INSTALL_DIR}

# Remove false-positives non-critical test keys
RUN find ${APP_INSTALL_DIR}/test -name "*.key" | xargs rm -f

# Install configurable-http-proxy according to package-lock.json (ci) without
# devDepdendencies (--production), then uninstall npm which isn't needed.
RUN npm ci --production && \
    npm uninstall -g npm

# Replace logs.js
COPY --chown=$NB_USER:root proxy/log.js ${APP_INSTALL_DIR}/lib/log.js

# Switch from the root user to the nobody user
USER ${NB_USER}

# Expose the proxy for traffic to be proxied (8000) and the
# REST API where it can be configured (8001)
EXPOSE 8000
EXPOSE 8001

HEALTHCHECK --start-period=10s CMD bash -c '</dev/tcp/127.0.0.1/8000 &>/dev/null' || exit 1

# Put configurable-http-proxy on path for chp-docker-entrypoint
ENV PATH=${APP_INSTALL_DIR}/bin:$PATH
ENV APP_INSTALL_DIR=${APP_INSTALL_DIR}
# ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash", "-l", "-c", "$APP_INSTALL_DIR/chp-docker-entrypoint"]