FROM docker:latest
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - -
# install ruby+
# tar is needed to tar-pipe test coverage out of tmpfs.
# tini is needed for pid-1 zombie reaping
# - - - - - - - - - - - - - - - -

RUN apk --update --upgrade --no-cache add \
    bash \
    ruby-bundler \
    ruby-dev \
    tar \
    tini

# - - - - - - - - - - - - - - - -
# install ruby gems
# - - - - - - - - - - - - - - - -

WORKDIR /app
COPY Gemfile .

RUN apk --update --upgrade add --virtual build-dependencies build-base \
  && bundle config --global silence_root_warning 1 \
  && bundle install \
  && gem clean \
  && apk del build-dependencies build-base \
  && rm -vrf /var/cache/apk/*

# Install util-linux to use script to allow ECS exec logging
RUN apk add util-linux

ARG COMMIT_SHA
ENV SHA=${COMMIT_SHA}
