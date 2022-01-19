# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=31.34.1

# Base image
#============
FROM renovate/buildpack:5@sha256:a21d804488fc6c06d421aba67a1c8793e9a5cb2e43ca8fa4557accbb10692917 AS base

LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

# renovate: datasource=node
RUN install-tool node v14.18.3

# renovate: datasource=npm versioning=npm
RUN install-tool yarn 1.22.17

WORKDIR /usr/src/app

# Build image
#============
FROM base as tsbuild

COPY . .

RUN set -ex; \
  yarn install; \
  yarn build; \
  chmod +x dist/*.js;

ARG RENOVATE_VERSION
RUN set -ex; \
  yarn version --new-version ${RENOVATE_VERSION}; \
  yarn add -E  renovate@${RENOVATE_VERSION} --production;  \
  node -e "new require('re2')('.*').exec('test')";


# Final image
#============
FROM base as final

# renovate: datasource=docker versioning=docker
RUN install-tool docker 20.10.12

# renovate: datasource=adoptium-java
RUN install-tool java 11.0.13+8

# renovate: datasource=gradle-version versioning=gradle
RUN install-tool gradle 6.9.2

RUN install-tool erlang 22.3.2

# renovate: datasource=docker versioning=docker
RUN install-tool elixir 1.13.1

# renovate: datasource=github-releases lookupName=containerbase/php-prebuild
RUN install-tool php 7.4.27

# renovate: datasource=github-releases lookupName=composer/composer
RUN install-tool composer 2.2.4

# renovate: datasource=docker versioning=docker
RUN install-tool golang 1.17.6

# renovate: datasource=github-releases lookupName=containerbase/python-prebuild
RUN install-tool python 3.10.2

# renovate: datasource=pypi
RUN install-pip pipenv 2020.11.15

# renovate: datasource=github-releases lookupName=python-poetry/poetry
RUN install-tool poetry 1.1.12

# renovate: datasource=pypi
RUN install-pip hashin 0.17.0

# renovate: datasource=pypi
RUN install-pip pip-tools 6.4.0

# renovate: datasource=docker versioning=docker
RUN install-tool rust 1.58.0

# renovate: datasource=github-releases lookupName=containerbase/ruby-prebuild
RUN install-tool ruby 3.1.0

# renovate: datasource=rubygems versioning=ruby
RUN install-gem cocoapods 1.11.2

# renovate: datasource=docker lookupName=mcr.microsoft.com/dotnet/sdk
RUN install-tool dotnet 6.0.101

# renovate: datasource=npm versioning=npm
RUN install-tool pnpm 6.26.0

# renovate: datasource=npm versioning=npm
RUN install-npm lerna 4.0.0

# renovate: datasource=github-releases lookupName=helm/helm
RUN install-tool helm v3.7.2

COPY --from=tsbuild /usr/src/app/package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist
COPY --from=tsbuild /usr/src/app/node_modules node_modules

# exec helper
COPY bin/ /usr/local/bin/
RUN ln -sf /usr/src/app/dist/renovate.js /usr/local/bin/renovate;
RUN ln -sf /usr/src/app/dist/config-validator.js /usr/local/bin/renovate-config-validator;
CMD ["renovate"]


RUN set -ex; \
  renovate --version; \
  renovate-config-validator; \
  node -e "new require('re2')('.*').exec('test')";

ARG RENOVATE_VERSION
LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
