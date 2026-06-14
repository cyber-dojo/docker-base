FROM docker:29.5.3-dind-alpine3.24@sha256:ad68e89b675740867a3bb96488a93fea9209ad36c6305bfba2664912d6dcf11a
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
