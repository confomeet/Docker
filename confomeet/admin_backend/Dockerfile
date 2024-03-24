FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /app/ConfOMeetBackend

ARG ADMIN_FRONTEND_GIT_USER
ENV ADMIN_FRONTEND_GIT_USER=${ADMIN_FRONTEND_GIT_USER}
ARG ADMIN_FRONTEND_GIT_PASS
ENV ADMIN_FRONTEND_GIT_PASS=${ADMIN_FRONTEND_GIT_PASS}
ARG ADMIN_BACKEND_BRANCH
ENV ADMIN_BACKEND_BRANCH=${ADMIN_BACKEND_BRANCH}

COPY rootfs /

# Installing tpl in order to use .tpl file for configuration from env variables.
# Note: At some point microsoft can delete wget from basic dotnet build container. If it happens just install wget in container by hand.
RUN \
    dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
        "amd64") TPL_ARCH=amd64 ;; \
        "arm64") TPL_ARCH=arm64 ;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget -qO /usr/bin/tpl https://github.com/jitsi/tpl/releases/download/v1.1.1/tpl-linux-${TPL_ARCH} && \
    chmod +x /usr/bin/tpl

RUN git clone https://${ADMIN_FRONTEND_GIT_USER}:${ADMIN_FRONTEND_GIT_PASS}@code.event33.ru/confomeet/ConfOMeetBackend.git . && \
    git checkout ${ADMIN_BACKEND_BRANCH}

# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -c Release -o /app

WORKDIR /app
ENTRYPOINT /app/run.sh

