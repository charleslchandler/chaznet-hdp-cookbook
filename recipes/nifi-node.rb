#
# Cookbook Name:: chaznet-hdp
# Recipe:: nifi-node
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'chaznet-hdp::nifi'

manager_fqdn = 'hdp01-nifi-ncm.chaznet.local'
#manager_fqdn = search(:node, 'recipes:"chaznet-hdp::nifi-cluster-manager"').first[:fqdn]
node_fqdn = node[:fqdn]

template '/opt/nifi/conf/nifi.properties' do
  source 'nifi.properties.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    is_manager: false,
    manager_fqdn: manager_fqdn,
    manager_port: 10240,
    node_port: 10241,
    node_fqdn: node_fqdn
  })
  action :create
end
