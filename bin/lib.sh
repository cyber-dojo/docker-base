#!/usr/bin/env bash
set -Eeu

build_image()
{
  docker build \
    --build-arg COMMIT_SHA="$(git_commit_sha)" \
    --tag "$(image_name)" \
    "${REPO_ROOT}"

  assert_equal SHA "$(git_commit_sha)" "$(image_sha)"
}

git_commit_sha()
{
  cd "${REPO_ROOT}" && git rev-parse HEAD
}

image_name()
{
  echo cyberdojo/docker-base
}

image_sha()
{
  docker run --rm $(image_name):latest sh -c 'echo ${SHA}'
}

image_tag()
{
  local -r sha="$(git_commit_sha)"
  echo "${sha:0:7}"
}

tag_image()
{
  local -r image="$(image_name)"
  local -r tag="$(image_tag)"
  docker tag "${image}:latest" "${image}:${tag}"
  echo "$(git_commit_sha)"
  echo "${tag}"
}

on_ci_publish_tagged_image()
{
  if ! on_ci; then
    echo 'not on CI so not publishing tagged image'
  else
    echo 'on CI so publishing tagged image'
    local -r image="$(image_name)"
    local -r tag="$(image_tag)"
    docker push ${image}:latest
    docker push ${image}:${tag}
  fi
}

on_ci()
{
  [ "${CI:-}" == true ]
}

assert_equal()
{
  local -r name="${1}"
  local -r expected="${2}"
  local -r actual="${3}"
  echo "expected: ${name}='${expected}'"
  echo "  actual: ${name}='${actual}'"
  if [ "${expected}" != "${actual}" ]; then
    echo "ERROR: unexpected ${name} inside image ${IMAGE}:latest"
    exit 42
  fi
}

