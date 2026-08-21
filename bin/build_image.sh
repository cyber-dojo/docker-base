#!/usr/bin/env bash
set -Eeu

export REPO_ROOT="$( cd "$( dirname "${0}" )/.." && pwd )"
source "${REPO_ROOT}/bin/lib.sh"

build_image
tag_image
# After tagging, so removing an earlier build's tags takes its last tag with
# them and the image itself goes, rather than being left dangling when :latest
# moves to this build.
remove_old_images
