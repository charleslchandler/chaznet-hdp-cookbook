#
# Cookbook Name:: chaznet-hdp
# Recipe:: hdp-cloud
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require_recipe 'chaznet-hdp::hdp-base'

fqdn = "#{node.name}.#{node['dns']['domain_name']}"

template '/var/lib/cloud/data/previous-hostname' do
  source 'hostname.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({hostname: fqdn})
  action :create
end
