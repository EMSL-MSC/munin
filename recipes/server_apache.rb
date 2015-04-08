#
# Cookbook Name:: munin
# Recipe:: server_apache
#
# Copyright 2013, Opscode, Inc.
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

if platform_family?('rhel', 'fedora')
  node.default['apache']['default_modules'] << 'expires'
end

include_recipe 'apache2::default'
include_recipe 'apache2::mod_rewrite'

if node['munin'].fetch('graph_strategy', 'cron') == 'cgi'
  node.override['apache']['user'] = 'apache'
  node.override['apache']['group'] = 'apache'
  include_recipe 'apache2::mod_fcgid'
  directory '/var/run/httpd/mod_fcgid' do
    owner 'apache'
    group 'apache'
    mode '0755'
    recursive true
    action :create
    notifies :restart, 'service[apache2]'
  end
  file '/var/run/httpd/mod_fcgid/fcgid_shm' do
    owner 'apache'
    group 'apache'
    mode '0755'
    notifies :restart, 'service[apache2]'
  end
end
%w( munin-cgi-graph munin-cgi-html ).each do |scg|
  file "/var/www/cgi-bin/#{scg}" do
    owner 'apache'
    group 'apache'
    mode '0755'
    action :touch
    notifies :restart, 'service[apache2]'
  end
end

apache_site '000-default' do
  enable false
end

template "#{node['apache']['dir']}/sites-available/munin.conf" do
  source 'apache2.conf.erb'
  mode '0644'
  if ::File.symlink?("#{node['apache']['dir']}/sites-enabled/munin.conf")
    notifies :restart, 'service[apache2]'
  end
end

apache_site 'munin'
