#!/usr/bin/env bash
set -Eeu

export REPO_ROOT="$( cd "$( dirname "${0}" )/.." && pwd )"
source "${REPO_ROOT}/bin/lib.sh"

build_image
tag_image
