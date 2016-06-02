#
# Cookbook Name:: chaznet-hdp
# Recipe:: hdp-hardware
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

public_ip       = node[:ipaddress]

require_recipe 'chaznet-hdp::hdp-base'
