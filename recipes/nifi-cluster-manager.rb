#
# Cookbook Name:: chaznet-hdp
# Recipe:: nifi-cluster-manager
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'chaznet-hdp::nifi'

#manager_fqdn = 'hdp01-nifi-ncm.chaznet.local'
#manager_fqdn = node[:fqdn]
manager_fqdn = node['nifi']['cluster_manager']

template '/opt/nifi/conf/nifi.properties' do
  source 'nifi.properties.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    is_manager: true,
    manager_fqdn: manager_fqdn,
    manager_port: 10240,
    node_port: 10241,
    node_fqdn: manager_fqdn
  })
  action :create
end
