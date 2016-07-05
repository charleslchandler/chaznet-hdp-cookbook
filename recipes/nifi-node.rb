#
# Cookbook Name:: chaznet-hdp
# Recipe:: nifi-node
#
# Copyright (c) 2016 Chaz Chandler, All Rights Reserved.

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

require 'chef-vault'

include_recipe 'chaznet-hdp::nifi'

manager_fqdn = node['nifi']['cluster_manager']
#manager_fqdn = search(:node, 'recipes:"chaznet-hdp::nifi-cluster-manager"').first[:fqdn]
vault = ChefVault::Item.load("passwords", "nifi")

template '/opt/nifi/conf/nifi.properties' do
  source 'nifi.properties.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    is_manager:    false,
    manager_fqdn:  manager_fqdn,
    manager_port:  node['nifi']['manager_port'],
    node_port:     node['nifi']['node_port'],
    node_fqdn:     node['fqdn'],
    nifi_version:  node['nifi']['version'],
    sensitive_key: vault['sensitive_key']
  })
  action :create
end
