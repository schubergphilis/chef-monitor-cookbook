#
# Author:: Sander Botman (<sander.botman@gmail.com>)
# Copyright:: Copyright (c) 2014 Sander Botman.
# License:: Apache License, Version 2.0
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
#
# Cookbook Name:: chef_monitor
# Attribute:: default
#
default['chef_monitor']['download_path'] = "/opt/chef-monitor/orgs"
default['chef_monitor']['install_dir']   = "/opt/chef-monitor"
default['chef_monitor']['client_key']    = "/opt/chef-monitor/monitor.pem"
default['chef_monitor']['mq_server']     = "127.0.0.1"
default['chef_monitor']['node_name']     = "monitor"
default['chef_monitor']['mon_file']      = "/var/log/opscode/nginx/access.log"
default['chef_monitor']['mq_queue']      = "monitor_tasks"
default['chef_monitor']['chef_url']      = "https://127.0.0.1"
default['chef_monitor']['log_dir']       = "/var/log/chef-monitor"
default['chef_monitor']['pid_dir']       = "/var/run/chef-monitor"

default['chef_monitor']['emaildomain']   = "@yourdomain.com"
default['chef_monitor']['project']       = "CHEF"
