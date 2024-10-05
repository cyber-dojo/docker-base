ARG BASE_IMAGE=docker:27.3.1-dind-alpine3.20
FROM ${BASE_IMAGE}
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - -
# install ruby+
# - tar is needed to tar-pipe test coverage out of tmpfs.
# - tini is needed for pid-1 zombie reaping
# - util-linux to use `script` to allow ECS exec logging
# - - - - - - - - - - - - - - - -

RUN apk --update --upgrade --no-cache add \
    bash \
    ruby-bundler \
    ruby-dev \
    tar \
    tini \
    util-linux

RUN apk add libcurl=8.10.1-r0  # https://security.snyk.io/vuln/SNYK-ALPINE320-CURL-7931858
RUN apk add grpc               # https://security.snyk.io/vuln/SNYK-GOLANG-GITHUBCOMOPENCONTAINERSRUNCLIBCONTAINERUTILS-7856945

WORKDIR /app
COPY Gemfile .

RUN apk --update --upgrade add --virtual build-dependencies build-base \
  && bundle config --global silence_root_warning 1 \
  && bundle install \
  && gem clean \
  && apk del build-dependencies build-base \
  && rm -vrf /var/cache/apk/*

ARG COMMIT_SHA
ENV SHA=${COMMIT_SHA}

# ARGs are reset after FROM See https://github.com/moby/moby/issues/34129
ARG BASE_IMAGE
ENV BASE_IMAGE=${BASE_IMAGE}
