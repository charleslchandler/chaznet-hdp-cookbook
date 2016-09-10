#
# Cookbook Name:: chaznet-hdp
# Recipe:: hdp-hardware
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require_recipe 'chaznet-hdp::hdp-base'

platform         = node[:platform]
platform_version = node[:platform_version].to_i
artifacts_uri    = node['artifacts']['base_uri']


case platform
when 'centos'

  if platform_version == 6
    # workaround to:
    #
    # resource_management.core.exceptions.Fail: Execution of '/usr/bin/yum -d 0 -e 0 -y install mysql-connector-java' returned 1.
    # Error: Package: 1:java-1.8.0-openjdk-1.8.0.101-3.b13.el6_8.x86_64 (CentOS-Updates)
    #            Requires: java-1.8.0-openjdk-headless = 1:1.8.0.101-3.b13.el6_8
    #            Installing: 1:java-1.8.0-openjdk-headless-1.8.0.51-1.b16.el6_7.x86_64 (elasticsearch_kibana-0.7.3)
    #                java-1.8.0-openjdk-headless = 1:1.8.0.51-1.b16.el6_7
    # Error: Package: 1:java-1.8.0-openjdk-1.8.0.101-3.b13.el6_8.x86_64 (CentOS-Updates)
    #            Requires: java-1.8.0-openjdk-headless = 1:1.8.0.101-3.b13.el6_8
    #            Available: 1:java-1.8.0-openjdk-headless-1.8.0.51-1.b16.el6_7.x86_64 (elasticsearch_kibana-0.7.3)
    #                java-1.8.0-openjdk-headless = 1:1.8.0.51-1.b16.el6_7
    remote_file '/tmp/java-1.8.0-openjdk-headless-1.8.0.101-3.b13.el6_8.x86_64.rpm' do
      source "#{artifacts_uri}/java/java-1.8.0-openjdk-headless-1.8.0.101-3.b13.el6_8.x86_64.rpm"
      action :create
    end
  
    package 'java-1.8.0-openjdk-headless' do
      source '/tmp/java-1.8.0-openjdk-headless-1.8.0.101-3.b13.el6_8.x86_64.rpm'
      action :install
    end
  end

end
