#
# Cookbook Name:: chaznet-hdp
# Recipe:: nifi
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'tarball::default'

username    = node['nifi']['username']
install_dir = node['nifi']['install_dir']

user username do
  comment 'NiFi PrivSep account'
  shell '/bin/bash'
  manage_home true
  non_unique false
  action :create
end

template '/etc/security/limits.d/90-nifi.conf' do
  source 'limits-90-nifi.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    username: username
  })
  action :create
end

cookbook_file '/etc/sysctl.d/90-nifi.conf' do
  source 'sysctl-90-nifi.conf'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

artifacts_uri = node['artifacts']['base_uri']
version       = node['nifi']['version']
tarball       = "nifi-#{version}-bin.tar.gz"
local_tb      = "/tmp/#{tarball}"
remote_tb     = "#{artifacts_uri}/nifi/#{tarball}"
sha256        = node['nifi']['sha256']
remote_file local_tb do
  source remote_tb
  checksum sha256
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

tarball local_tb do
  destination install_dir
  owner username
  group username
  umask 002
  action :extract
  not_if "test -d #{install_dir}/nifi-#{version}"
end

link "#{install_dir}/nifi" do
  to "#{install_dir}/nifi-#{version}"
  link_type :symbolic
end

template "#{install_dir}/nifi-#{version}/conf/bootstrap.conf" do
  source 'nifi-bootstrap.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    username: username
  })
  action :create
end

cookbook_file "#{install_dir}/nifi-#{version}/conf/logback.xml" do
  source 'nifi-logback.xml'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

zk_connect_string = %x[grep '^server\.[0-9]*=' /etc/zookeeper/conf/zoo.cfg | cut -d= -f 2].chomp.gsub(/\n/, ",")

template "#{install_dir}/nifi-#{version}/conf/state-management.xml" do
  source 'nifi-state-management.xml.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    nifi_zk_connect_string: zk_connect_string,
    nifi_state_root_node: node['nifi']['state_management']['root_node']
  })
  action :create
end

