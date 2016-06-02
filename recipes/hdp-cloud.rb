#
# Cookbook Name:: chaznet-hdp
# Recipe:: hdp-cloud
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

public_ip       = %x(curl http://169.254.169.254/2009-04-04/meta-data/public-ipv4).chomp

require_recipe 'chaznet-hdp::hdp-base'

template '/var/lib/cloud/data/previous-hostname' do
  source 'hostname.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({hostname: fqdn})
  action :create
end
