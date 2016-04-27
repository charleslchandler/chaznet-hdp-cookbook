#
# Cookbook Name:: chaznet-hdp
# Recipe:: ambari-server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require_recipe "chaznet-hdp::ambari"

platform = node[:platform]

case platform
when 'redhat', 'centos'
  require_recipe 'selinux::disabled'
end

package 'ambari-server'

case platform
when 'ubuntu'

  execute 'ensure update of ambari-server' do
    command 'apt-get install -y ambari-server'
  end

when 'redhat', 'centos'

  execute 'ensure update of ambari-server' do
    command 'yum update -y ambari-server'
  end

  service 'iptables' do
    action [ :stop, :disable ]
  end

end
