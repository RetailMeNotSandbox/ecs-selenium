include ../../.env
export $(shell sed 's/=.*//' ../../.env)

VERSION=3.8.1
REGISTRY=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

clean:
	rm -rf common

build:
	mkdir -p common/
	rsync -av --exclude='selenium' --exclude='Makefile' ../common/* common/
	docker build -t ecs-node-chrome --build-arg VERSION=$(VERSION) .
	rm -rf common/

tag: build
	docker tag ecs-node-chrome $(REGISTRY)/ecs-node-chrome:$(VERSION)
	docker tag ecs-node-chrome $(REGISTRY)/ecs-node-chrome:latest

push: tag
	docker push $(REGISTRY)/ecs-node-chrome:$(VERSION)
	docker push $(REGISTRY)/ecs-node-chrome:latest
