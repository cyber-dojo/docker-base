
SHORT_SHA := $(shell git rev-parse HEAD | head -c7)
IMAGE_NAME := cyberdojo/docker-base:${SHORT_SHA}

.PHONY: image snyk-container

image:
	${PWD}/build_test_publish.sh

snyk-container-scan: image
	snyk container test ${IMAGE_NAME} \
        --file=Dockerfile \
		--sarif \
		--sarif-file-output=snyk.container.scan.json \
        --policy-path=.snyk

