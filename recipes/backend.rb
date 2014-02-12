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
# Recipe:: backend
#

bin_dir      = File.dirname(RbConfig.ruby)
options      = node['chef_monitor'].to_hash
install_dir  = options['install_dir']
pid_dir      = options['pid_dir']
log_dir      = options['log_dir']
project      = options['project']
download_dir = options['download_path']

[install_dir, download_dir, pid_dir, log_dir].each do |dir|
  directory dir do
    owner "root"
    group "root"
    mode 0700
    action :create
    recursive true
  end
end

%w[ bunny daemons chef-monitor ].each do |pkg|
  chef_gem pkg do
    action :install
  end
end

template "/etc/init.d/chef-worker" do
  source "chef-init.erb"
  mode 0750
  variables(
    :recipe_file   => (__FILE__).to_s.split("cookbooks/").last,
    :template_file => source.to_s,
    :install_dir   => install_dir,
    :bin_dir       => bin_dir,
    :srv_name      => "chef-worker"
  )
  notifies :restart, "service[chef-worker]", :delayed
end

template "#{install_dir}/config.rb" do
  source "config.rb.erb"
  mode 0600
  variables(
    :recipe_file   => (__FILE__).to_s.split("cookbooks/").last,
    :template_file => source.to_s,
    :options       => options
  )
  notifies :restart, "service[chef-worker]", :delayed
end

template "#{install_dir}/post-commit" do
  source "post-commit.erb"
  mode 0750
  variables(
    :recipe_file   => (__FILE__).to_s.split("cookbooks/").last,
    :template_file => source.to_s,
    :install_dir   => install_dir
  )
end

template "#{install_dir}/parse2htmlmail.pl" do
  source "parse2htmlmail.pl.erb"
  mode 0750
  variables(
    :recipe_file   => (__FILE__).to_s.split("cookbooks/").last,
    :template_file => source.to_s,
    :project       => project
  )
end

package "git" do
  action :install
end

unless node['chef_monitor'].nil? || node['chef_monitor']['orgs'].nil?
  node['chef_monitor']['orgs'].each do |k,v|

    dir = "#{download_dir}/#{k}"

    directory dir do
      owner "root"
      group "root"
      mode 0700
      action :create
    end
  
    bash "init_#{dir}" do
      code <<-EOH
        cd "#{dir}"
        git init
        touch README.md
        git add .
        git commit -am "initialize repo"
      EOH
      not_if { ::File.directory?("#{dir}/.git") }
    end

    bash "hooks_#{dir}" do
      code <<-EOH
        cd "#{dir}"
        git config hooks.mailinglist #{v['mailinglist']}
        git config hooks.emaildomain #{options['emaildomain']}
        git config hooks.emaildomain #{v['emaildomain']}
        git config hooks.tag #{v['tag']}
      EOH
    end

    link "#{dir}/.git/hooks/post-commit" do
      to "#{install_dir}/post-commit"
      only_if { ::File.directory?("#{dir}/.git/hooks") }
    end


  end
end

service "chef-worker" do
    supports :status => true, :restart => true
    action :enable
end
