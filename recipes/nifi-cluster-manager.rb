#
# Cookbook Name:: chaznet-hdp
# Recipe:: nifi-cluster-manager
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'chaznet-hdp::nifi'

#manager_fqdn = node['fqdn']
manager_fqdn = node['nifi']['cluster_manager']

template '/opt/nifi/conf/nifi.properties' do
  source 'nifi.properties.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    is_manager:   true,
    manager_fqdn: manager_fqdn,
    manager_port: node['nifi']['manager_port'],
    node_port:    node['nifi']['node_port'],
    node_fqdn:    manager_fqdn,
    nifi_version: node['nifi']['version']
  })
  action :create
end
