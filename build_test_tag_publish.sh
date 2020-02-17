#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && pwd )"

# - - - - - - - - - - - - - - - - - - - - - - - -
build_image()
{
  docker build \
    --build-arg COMMIT_SHA="$(git_commit_sha)" \
    --tag "$(image_name)" \
    "${ROOT_DIR}/app"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
git_commit_sha()
{
  echo $(cd "${ROOT_DIR}" && git rev-parse HEAD)
}

# - - - - - - - - - - - - - - - - - - - - - - - -
my_name()
{
  echo docker-base
}

# - - - - - - - - - - - - - - - - - - - - - - - -
image_name()
{
  echo "cyberdojo/$(my_name)"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
image_sha()
{
  docker run --rm $(image_name):latest sh -c 'echo ${SHA}'
}

# - - - - - - - - - - - - - - - - - - - - - - - -
image_tag()
{
  local -r sha="$(git_commit_sha)"
  echo "${sha:0:7}"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
tag_image()
{
  local -r image="$(image_name)"
  local -r tag="$(image_tag)"
  docker tag "${image}:latest" "${image}:${tag}"
  echo "$(git_commit_sha)"
  echo "${tag}"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
on_ci_publish_tagged_image()
{
  if ! on_ci; then
    echo 'not on CI so not publishing tagged image'
    return
  fi
  echo 'on CI so publishing tagged image'
  local -r image="$(image_name)"
  local -r tag="$(image_tag)"
  # DOCKER_USER, DOCKER_PASS are in ci context
  echo "${DOCKER_PASS}" | docker login --username "${DOCKER_USER}" --password-stdin
  docker push ${image}:latest
  docker push ${image}:${tag}
  docker logout
}

# - - - - - - - - - - - - - - - - - - - - - - - -
on_ci()
{
  [ -n "${CIRCLECI}" ]
}

# - - - - - - - - - - - - - - - - - - - - - - - -
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

# - - - - - - - - - - - - - - - - - - - - - - - -
on_ci_trigger_dependent_images()
{
  if ! on_ci; then
    echo 'not on CI so not triggering dependent images'
    return
  fi
  echo 'on CI so triggering dependent images'
  curl_trigger_script
  local -r from_org=cyber-dojo
  local -r from_repo="$(my_name)"
  local -r from_sha="$(git_commit_sha)"
  local -r to_org=cyber-dojo
  local -r to_repos="commander ragger runner"
  $(trigger_script_path) \
    "${from_org}" "${from_repo}" "${from_sha}" \
    "${to_org}" "${to_repos}"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
curl_trigger_script()
{
  local -r raw_github_org=https://raw.githubusercontent.com/cyber-dojo
  local -r repo=cyber-dojo
  local -r branch=master
  local -r path=sh/circle-ci
  local -r url="${raw_github_org}/${repo}/${branch}/${path}/$(trigger_script_name)"
  curl -O --silent --fail "${url}"
  chmod 700 "$(trigger_script_path)"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
trigger_script_path()
{
  echo "./$(trigger_script_name)"
}

# - - - - - - - - - - - - - - - - - - - - - - - -
trigger_script_name()
{
  echo github_automated_commit_push.sh
}

# - - - - - - - - - - - - - - - - - - - - - - - -
build_image
tag_image
assert_equal SHA "$(git_commit_sha)" "$(image_sha)"
on_ci_publish_tagged_image
#on_ci_trigger_dependent_images
