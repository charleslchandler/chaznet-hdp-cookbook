#
# Cookbook Name:: chaznet-hdp
# Recipe:: ambari-agent
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "chaznet-hdp::ambari"

package 'ambari-agent'

platform        = node[:platform]
release_version = node[:platform_version].to_i

case platform
when 'ubuntu'

  execute 'ensure update of ambari-agent' do
    command 'apt-get install -y ambari-agent'
  end

  if File.exist?('/usr/lib/python2.6/site-packages/resource_management/core/providers/package/apt.py')
    cookbook_file '/usr/lib/python2.6/site-packages/resource_management/core/providers/package/apt.py' do
      source 'apt.py'
      owner 'root'
      group 'root'
      mode '0755'
    end
  end

when 'redhat', 'centos'

  execute 'ensure update of ambari-agent' do
    command 'yum update -y ambari-agent'
  end

end

ambari_server_fqdn = node['ambari']['server']['fqdn']
ambari_server_ip   = node['ambari']['server']['ipaddress']

template '/etc/ambari-agent/conf/ambari-agent.ini' do
  source 'ambari-agent.ini.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({ambari_server: ambari_server_fqdn})
  action :create
end

execute 'ensure server is in /etc/hosts' do
  command "echo '#{ambari_server_ip} #{ambari_server_fqdn}' >> /etc/hosts"
  not_if "grep '^#{ambari_server_ip} #{ambari_server_fqdn}' /etc/hosts"
end

service 'ambari-agent' do
  action [ :enable, :start ]
end

case platform
when 'redhat', 'centos'

  if release_version >= 7
    # not sure why but the service resource doesn't seem to actually enable/start ambari-agent on centos7

    execute 'ensure enable of ambari-agent' do
      command 'systemctl enable ambari-agent'
    end
  end

end
