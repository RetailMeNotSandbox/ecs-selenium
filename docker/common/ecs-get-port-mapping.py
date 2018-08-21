# Copyright 2016 Chris Smith
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import boto3
import requests


def get_contents(filename):
    with open(filename) as f:
        return f.read()


def get_ecs_introspection_url(resource):
    # 172.17.0.1 is the docker network bridge ip
    return 'http://172.17.0.1:51678/v1/' + resource


def contains_key(d, key):
    return key in d and d[key] is not None


def get_local_container_info():
    # get the docker container id
    # http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-introspection.html
    docker_id = os.path.basename(get_contents("/proc/1/cpuset")).strip()

    if docker_id is None:
        raise Exception("Unable to find docker id")

    ecs_local_task = requests.get(get_ecs_introspection_url('tasks') + '?dockerid=' + docker_id).json()

    task_arn = ecs_local_task['Arn']

    if task_arn is None:
        raise Exception("Unable to find task arn for container %s in ecs introspection api" % docker_id)

    ecs_local_container = None

    if contains_key(ecs_local_task, 'Containers'):
        for c in ecs_local_task['Containers']:
            container_docker_id = c.get('DockerId') or c.get('DockerID')
            if container_docker_id == docker_id:
                ecs_local_container = c

    if ecs_local_container is None:
        raise Exception("Unable to find container %s in ecs introspection api" % docker_id)

    return ecs_local_container['Name'], task_arn


def main():

    region = os.environ["AWS_REGION"]

    ecs_metadata = requests.get(get_ecs_introspection_url('metadata')).json()
    cluster = ecs_metadata['Cluster']

    container_name, task_arn = get_local_container_info()

    # Get the container info from ECS. This will give us the port mappings
    ecs = boto3.client('ecs', region_name=region)
    response = ecs.describe_tasks(
        cluster=cluster,
        tasks=[
            task_arn,
        ]
    )

    task = None
    if contains_key(response, 'tasks'):
        for t in response['tasks']:
            if t['taskArn'] == task_arn:
                task = t

    if task is None:
        raise Exception("Unable to locate task %s" % task_arn)

    containerInstanceId = task["containerInstanceArn"].split("/")[-1]
    print("export NODE_ID='%s';" % task_arn.split("/")[-1])
    response = ecs.describe_container_instances(
        cluster=os.environ["CLUSTER"],
        containerInstances=[
            containerInstanceId,
        ]
    )
    instance_id = response["containerInstances"][0]["ec2InstanceId"]

    ec2 = boto3.resource('ec2', region_name=region)
    instance = ec2.Instance(instance_id)
    print("export EC2_HOST=%s;" % instance.private_ip_address)

    container = None
    if contains_key(task, 'containers'):
        for c in task['containers']:
            if c['name'] == container_name:
                container = c

    if container is None:
        raise Exception("Unable to find ecs container %s" % container_name)

    if contains_key(container, 'networkBindings'):
        for b in container['networkBindings']:
            print("export PORT_%s_%d=%d;" % (b['protocol'].upper(), b['containerPort'], b['hostPort']))


if __name__ == '__main__':
    main()
