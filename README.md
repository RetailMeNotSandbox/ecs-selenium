ecs-selenium
=========

## Introduction

`ecs-selenium` includes CloudFormation scripts for a reference implementation of a [Selenium Grid](https://github.com/SeleniumHQ/selenium/wiki/Grid2) running on [Amazon's EC2 Container Service](https://aws.amazon.com/ecs/).

## Design

The reference implementation consists of two ECS Clusters. A cluster for the hub, and another for the nodes.

The reasoning behind this is that we wouldn't want the hub competing with the nodes for resources, nor would we want a SpotFleet pricing mismatch to take down the Hub.

### The Hub

![The Hub](docs/img/hub-cfn.png)

The Hub consists of a single instance and an ECS Cluster with a selenium server running in _hub_ mode (`-role hub`) for each node type (Firefox, Chrome). An [Application Load Balancer](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) sits in front of it. The ALB uses the hostname prefix to route requests to the correct hub.

### The Nodes

![The Nodes](docs/img/nodes-cfn.png)

The nodes component of the stack consists of an ECS Cluster with a couple of services, task definitions (one of each for Firefox, and Chrome), and a [Spot Fleet](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet.html) to provide the underlying hardware.

> *Note:* An AutoScaling Group is also provided as fall-back; in case Spot Fleet doesn't fit your needs. All you need to do is scale it up.

## Selenium

### Create the ECR Repositories

Create your repositories before building the images. These commands only need to be run once.

```
# create the ecr ecs-node-firefox repository
aws --region <region> ecr create-repository --repository-name ecs-node-firefox

# create the ecr ecs-node-chrome repository
aws --region <region> ecr create-repository --repository-name ecs-node-chrome
```

### Build the Images

You now need to build and push the node images to your docker registry. ECR is assumed by default. You can rebuild your images periodically to get newer browsers in your cluster.

```bash
# setup environment
echo "AWS_ACCOUNT_ID=111122223333" > .env
echo "AWS_REGION=<region>" >> .env

# login to ecr
$(aws ecr get-login --no-include-email)

# build and push firefox
cd docker/ecs-node-firefox
make push

# build and push chrome
cd docker/ecs-node-chrome
make push
```

## Setup

To get a Selenium Grid up and running with ECS, run the following command (replacing the parameters with appropriate values):

```bash
aws cloudformation (create-stack|update-stack) \
--stack-name "ecs-selenium" --capabilities CAPABILITY_NAMED_IAM \
--template-body file://./cloudformation/ecs-selenium.cfn.yml \
--parameters ParameterKey=VpcId,ParameterValue="<vpc-########>" \
             ParameterKey=KeyName,ParameterValue="<keypair>" \
             ParameterKey=SubnetIds,ParameterValue=\"<subnet-xyz123>,<subnet-xyz456>\" \
             ParameterKey=HubInstanceType,ParameterValue="c5.xlarge" \
             ParameterKey=NodeInstanceType,ParameterValue="c5.xlarge" \
             ParameterKey=AdminCIDR,ParameterValue="<cidr_for_admin_access>" \
             ParameterKey=DesiredFleetCapacity,ParameterValue="<#>" \
             ParameterKey=DesiredChromeNodes,ParameterValue="<#>" \
             ParameterKey=DesiredFirefoxNodes,ParameterValue="<#>" \
             ParameterKey=DomainName,ParameterValue="<company.com>" \
             ParameterKey=NodeFirefoxImage,ParameterValue="<location_of_your_ecs-node-firefox_image>" \
             ParameterKey=NodeChromeImage,ParameterValue="<location_of_your_ecs-node-chrome_image>"
```


## Scaling

### Up

The hub handles the scaling of the node services dynamically by comparing the hub's slot availability and the number of tasks that are queued in the corresponding hub. Scaling up is done every two minutes.

Keep in mind that _only_ the number of desired tasks for the service are scaled, and it depends on the EC2 instance infrastructure being readily available.

### Down

The template includes a parameter for setting up a time to scale down the number of nodes back to the default desired capabilities. By default, it is setup to scale down at 12AM UTC. You can update the `ScaleDownCron` parameter with values that work for your timezone.

### Manual Scaling

Additionally you can manually scale the services via API calls:

```bash
# chrome
aws ecs update-service --cluster ecs-selenium-nodes --service ecs-node-chrome --desired-count <#>

# firefox
aws ecs update-service --cluster ecs-selenium-nodes --service ecs-node-firefox --desired-count <#>
```

## Using the Grid

The template creates a Route53 hosted zone that can be used inside your VPC. By default, it uses the `example.com` domain name. You can change that by updating the `DomainName` parameter.

Inside your VPC, hosts can connect to the hubs using the following endpoints:

* `firefox.example.com:4444`
* `chrome.example.com:4444`

The ALB uses the domain name prefix to redirect to the proper hub. Domains starting with `firefox.*` will hit the Firefox hub; domains starting with `chrome.*` will hit the Chrome one.

## Troubleshooting
### Errors that occur when creating the stack
`Service arn:aws:ecs:us-west-1:1234567890:service/ecs-node-firefox did not stabilize.`

We've seen this in situations where the cluster is unable to provision the desired amount of nodes. There will be a mismatch between the Desired tasks value and the Running tasks value in the ECS console (Elastic Container Service -> ecs-selenium-nodes -> Services (tab).

It's usually due to hardware capacity. Here's what I would check:

* Did you actually get any spot instances? (EC2 -> Spot Requests -> Capacity Column (in the table)
If you didn't get any instances, your bid price may be too low for the region. You can update the MaxSpotBidPrice parameter to something that works for you. (The default is set pretty low, so depending on the region, you may be outbid by others.)

* You can look at the SpotFleet's History tab, and it will tell you if it was unable to provision instances due to your bid being too low.

* Do you have enough EC2 capacity for the number of nodes you desire?
MemoryReservation is set to 1024 per node. So you'd need 1024 MB * Number of Desired Nodes for it to provision successfully.
If you don't have enough instances for your nodes, you can increase DesiredFleetCapacity to match it, or you can decrease DesiredChromeNodes and DesiredFirefoxNodes to a number that fits within your provisioned instances.

* The fact that you don't have any entries in the ecs-selenium-nodes stream seems to indicate that it never provisioned a single node. So I'd start by looking at the SpotFleet.

### Check Cloudwatch for errors reported to the ecs-selenium logstream
