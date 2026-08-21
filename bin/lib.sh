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

# Keeps :latest, which image_sha and dependent repos read, and this commit's
# tag, which names the build just made. Every older tag goes, and an earlier
# build whose last tag was one of those goes with it, so local builds stop
# accumulating images.
remove_old_images()
{
  local -r name="$(image_name)"
  local -r tag="$(image_tag)"
  echo Removing old images
  # grep exits non-zero when the machine holds no docker-base image, eg one
  # whose images have just been cleared, so an empty list must not end the build.
  local tagged_name
  for tagged_name in $(docker image ls --format '{{.Repository}}:{{.Tag}}' | grep "^${name}:" || true)
  do
    if [ "${tagged_name}" != "${name}:latest" ] \
    && [ "${tagged_name}" != "${name}:${tag}" ]; then
      # Removing by name:tag untags, so this succeeds even while a container
      # references the image, leaving it dangling until that container goes.
      docker image rm --force "${tagged_name}" || echo "  skipped ${tagged_name} (in use)"
    fi
  done
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

