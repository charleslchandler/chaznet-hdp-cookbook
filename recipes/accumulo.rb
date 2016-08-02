#
# Cookbook Name:: chaznet-hdp
# Recipe:: accumulo
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

template '/etc/security/limits.d/90-accumulo.conf' do
  source 'limits-90-accumulo.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    username: 'accumulo'
  })
  action :create
end
