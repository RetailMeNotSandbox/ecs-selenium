#!/bin/bash

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

set -o errexit
set -o xtrace

result="$(python /opt/bin/ecs-get-port-mapping.py)"
eval "$result"

export SE_OPTS="-remoteHost http://$EC2_HOST:$PORT_TCP_5555 -id $NODE_ID"

# execute default extry_point.sh file
/opt/bin/entry_point.sh
