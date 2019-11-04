include ../../.env
export $(shell sed 's/=.*//' ../../.env)
VERSION=3.141.59

REGISTRY=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

clean:
	rm -rf common

build:
	mkdir -p common/
	rsync -av ../common/* common/
	docker build -t $(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE) --build-arg VERSION=$(VERSION) .
	rm -rf common/

tag: build
	docker tag $(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE) $(REGISTRY)/$(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE):$(VERSION)
	docker tag $(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE) $(REGISTRY)/$(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE):latest

push: tag
	docker push $(REGISTRY)/$(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE):$(VERSION)
	docker push $(REGISTRY)/$(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE):latest
