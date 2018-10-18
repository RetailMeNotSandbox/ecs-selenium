include ../../.env
export $(shell sed 's/=.*//' ../../.env)
VERSION=3.14.0

REGISTRY=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

clean:
	rm -rf common

build:
	mkdir -p common/
	rsync -av ../common/* common/
	docker build -t $(IMAGE_NAME) --build-arg VERSION=$(VERSION) .
	rm -rf common/

tag: build
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME):latest

push: tag
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
	docker push $(REGISTRY)/$(IMAGE_NAME):latest
