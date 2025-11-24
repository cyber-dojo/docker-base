
SHORT_SHA := $(shell git rev-parse HEAD | head -c7)
IMAGE_NAME := cyberdojo/docker-base:${SHORT_SHA}

.PHONY: image snyk-container

image:
	${PWD}/bin/build_image.sh

snyk-container-scan:
	snyk container test ${IMAGE_NAME} \
        --policy-path=.snyk \
		--sarif \
		--sarif-file-output=snyk.container.scan.json \

