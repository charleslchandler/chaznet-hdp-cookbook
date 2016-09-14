#
# Cookbook Name:: chaznet-hdp
# Recipe:: nifi
#
# Copyright (c) 2016 Chaz Chandler, All Rights Reserved.

require 'chef-vault'

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'tarball::default'

vault           = ChefVault::Item.load("passwords", "nifi")
mb_ram          = node['memory']['total'][0..-3].to_i / 1024
artifacts_uri   = node['artifacts']['base_uri']
username        = node['nifi']['username']
install_dir     = node['nifi']['install_dir']
is_clustered    = node['nifi']['is_clustered']
version         = node['nifi']['version']
sha256          = node['nifi']['sha256']
tarball         = "nifi-#{version}-bin.tar.gz"
local_tb        = "/tmp/#{tarball}"
remote_tb       = "#{artifacts_uri}/nifi/#{tarball}"
zk_clientport   = %x[grep '^clientPort=' /etc/zookeeper/conf/zoo.cfg | cut -d= -f 2].chomp
zk_servers      = %x[grep '^server\.[0-9]*=' /etc/zookeeper/conf/zoo.cfg | cut -d= -f 2 | cut -d: -f 1].chomp.split("\n")
zk_hostports    = zk_servers.map { |host| [ host, zk_clientport ].join(':') }
platform        = node[:platform]
release_version = node[:platform_version].to_i

user username do
  comment 'NiFi PrivSep account'
  shell '/bin/bash'
  manage_home true
  non_unique false
  action :create
end

template '/etc/security/limits.d/90-nifi.conf' do
  source 'limits-90-nifi.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  variables({
    username: username
  })
end

case platform
when 'redhat', 'centos'

  if release_version == 7

    cookbook_file '/etc/sysctl.d/90-nifi.conf' do
      source 'sysctl-90-nifi.conf'
      owner  'root'
      group  'root'
      mode   '0644'
      action :create
    end

  end

end

remote_file local_tb do
  source   remote_tb
  checksum sha256
  owner    'root'
  group    'root'
  mode     '0644'
  action   :create
end

tarball local_tb do
  destination install_dir
  owner       username
  group       username
  umask       002
  action      :extract
  not_if      "test -d #{install_dir}/nifi-#{version}"
end

link "#{install_dir}/nifi" do
  to        "#{install_dir}/nifi-#{version}"
  link_type :symbolic
end

template "#{install_dir}/nifi-#{version}/conf/bootstrap.conf" do
  source 'nifi-bootstrap.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  variables({
    username:    username,
    max_heap_mb: (mb_ram * 0.60).to_i,
    min_heap_mb: (mb_ram * 0.30).to_i
  })
end

cookbook_file "#{install_dir}/nifi-#{version}/conf/logback.xml" do
  source 'nifi-logback.xml'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
end

template "#{install_dir}/nifi-#{version}/conf/state-management.xml" do
  source 'nifi-state-management.xml.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  variables({
    zk_hostports:    zk_hostports,
    state_root_node: node['nifi']['state_management']['root_node']
  })
end

template '/opt/nifi/conf/nifi.properties' do
  source 'nifi.properties.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  variables({
    is_clustered:    is_clustered,
    node_port:       node['nifi']['node_port'],
    node_fqdn:       node['fqdn'],
    nifi_version:    node['nifi']['version'],
    sensitive_key:   vault['sensitive_key'],
    zk_hostports:    zk_hostports,
    state_root_node: node['nifi']['state_management']['root_node']
  })
end
