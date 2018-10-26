include ./.env
export $(shell sed 's/=.*//' ./.env)

NODE_FIREFOX_IMAGE=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECS_SELENIUM_FIREFOX_REPOSITORY_IMAGE):$(ECS_SELENIUM_FIREFOX_REPOSITORY_VERSION)

NODE_CHROME_IMAGE=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE):$(ECS_SELENIUM_CHROME_REPOSITORY_VERSION)

STACK_PARAMETERS=--parameters ParameterKey=VpcId,ParameterValue="$(ECS_SELENIUM_VPC_ID)" \
				  ParameterKey=KeyName,ParameterValue="$(ECS_SELENIUM_KEY_PAIR_NAME)" \
				  ParameterKey=SubnetIds,ParameterValue=\"$(ECS_SELENIUM_SUBNET_IDS)\" \
				  ParameterKey=HubInstanceType,ParameterValue="$(ECS_SELENIUM_HUB_INSTANCE_TYPE)" \
				  ParameterKey=NodeInstanceType,ParameterValue="$(ECS_SELENIUM_NODE_INSTANCE_TYPE)" \
				  ParameterKey=AdminCIDR,ParameterValue="$(ECS_SELENIUM_ADMIN_CIDR)" \
				  ParameterKey=DesiredFleetCapacity,ParameterValue="$(ECS_SELENIUM_DESIRED_FLEET_CAP)" \
				  ParameterKey=DesiredChromeNodes,ParameterValue="$(ECS_SELENIUM_DESIRED_CHROME_NODES)" \
				  ParameterKey=DesiredFirefoxNodes,ParameterValue="$(ECS_SELENIUM_DESIRED_FIREFOX_NODES)" \
				  ParameterKey=DomainName,ParameterValue="$(ECS_SELENIUM_DOMAIN_NAME)" \
				  ParameterKey=NodeFirefoxImage,ParameterValue="$(NODE_FIREFOX_IMAGE)" \
				  ParameterKey=NodeChromeImage,ParameterValue="$(NODE_CHROME_IMAGE)"


create-stack:
	aws cloudformation create-stack \
		--stack-name $(ECS_SELENIUM_STACK_NAME)  --capabilities CAPABILITY_NAMED_IAM \
		--template-body file://./cloudformation/ecs-selenium.cfn.yml \
		$(STACK_PARAMETERS)

update-stack:
	aws cloudformation update-stack \
		--stack-name $(ECS_SELENIUM_STACK_NAME)  --capabilities CAPABILITY_NAMED_IAM \
		--template-body file://./cloudformation/ecs-selenium.cfn.yml \
		$(STACK_PARAMETERS)

ecr-login:
	aws ecr --region $(AWS_REGION) get-login --no-include-email

ecr-create-firefox-node:
	aws --region $(AWS_AWS_REGION) ecr create-repository --repository-name $(ECS_SELENIUM_FIREFOX_REPOSITORY_IMAGE)

ecr-create-chrome-node:
	aws --region $(AWS_AWS_REGION) ecr create-repository --repository-name $(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE)

update-chrome-desired: # make count=<#> update-chrome-desired
	aws ecs update-service --cluster ecs-selenium-nodes \
		--service $(ECS_SELENIUM_CHROME_REPOSITORY_IMAGE) --desired-count $(count)

update-firefox-desired: # make count=<#> update-firefox-desired
	aws ecs update-service --cluster ecs-selenium-nodes \
		--service $(ECS_SELENIUM_FIREFOX_REPOSITORY_IMAGE) --desired-count $(count)
