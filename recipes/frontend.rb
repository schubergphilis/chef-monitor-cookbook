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
# Recipe:: frontend
#

bin_dir     = File.dirname(RbConfig.ruby)
options     = node['chef_monitor'].to_hash
install_dir = options['install_dir']
pid_dir     = options['pid_dir']
log_dir     = options['log_dir']

[install_dir, pid_dir, log_dir].each do |dir|
  directory dir do
    owner "root" 
    group "root"
    mode 0700
    action :create
    recursive true
  end
end

%w[ bunny daemons file-tail chef-monitor ].each do |pkg|
  chef_gem pkg do
    action :install
  end
end

template "/etc/init.d/chef-logmon" do
  source "chef-init.erb"
  mode 0755
  variables(
    :recipe_file   => (__FILE__).to_s.split("cookbooks/").last,
    :template_file => source.to_s,
    :install_dir   => install_dir,
    :bin_dir       => bin_dir,
    :srv_name      => "chef-logmon"
  )
  notifies :restart, "service[chef-logmon]", :delayed
end

template "#{install_dir}/config.rb" do
  source "config.rb.erb"
  mode 0600
  variables(
    :recipe_file   => (__FILE__).to_s.split("cookbooks/").last,
    :template_file => source.to_s,
    :options       => options
  )
  notifies :restart, "service[chef-logmon]", :delayed
end

service "chef-logmon" do
    supports :status => true, :restart => true
    action :enable
end
