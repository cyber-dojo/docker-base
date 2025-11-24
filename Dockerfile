#FROM docker:28.1.1-dind-alpine3.21
FROM docker:29.0.1-dind-alpine3.22

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
    tar \
    tini \
    util-linux

RUN git version
#RUN apk add --upgrade ruby-dev=3.3.10-r0  # https://security.snyk.io/vuln/SNYK-ALPINE321-RUBY-9802138
#RUN apk add --upgrade git=2.47.3-r0      # https://security.snyk.io/vuln/SNYK-ALPINE320-GIT-10669667

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
