FROM docker:27.4.0-dind-alpine3.21
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

RUN apk add openssl=3.3.2-r1   # https://security.snyk.io/vuln/SNYK-ALPINE320-OPENSSL-8235201
RUN apk add libcurl=8.11.0-r1  # https://security.snyk.io/vuln/SNYK-ALPINE320-CURL-8348469
RUN apk add libexpat=2.6.4-r0  # https://security.snyk.io/vuln/SNYK-ALPINE320-EXPAT-8359601
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
