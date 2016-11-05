#
# Cookbook Name:: chaznet-hdp
# Recipe:: ambari-server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require_recipe "chaznet-hdp::ambari"

hdp_version       = node[:hdp][:version]
hdp_utils_version = node[:hdp][:utils_version]
artifacts_uri     = node['artifacts']['base_uri']
platform          = node[:platform]
platform_version  = node[:platform_version].to_i
standard_services = node['ambari']['standard_services']
cluster_name      = node['ambari']['cluster_name']

case platform
when 'redhat', 'centos'
  require_recipe 'selinux::disabled'
end

package 'ambari-server'

case platform
when 'ubuntu'

  ambari_platform = "ubuntu#{platform_version}"
  hdp_platform    = "ubuntu#{platform_version}"

  execute 'ensure update of ambari-server' do
    command 'apt-get install -y ambari-server'
  end

when 'redhat', 'centos'

  ambari_platform = "redhat#{platform_version}"
  hdp_platform    = "centos#{platform_version}"

  execute 'ensure update of ambari-server' do
    command 'yum update -y ambari-server'
  end

  service 'iptables' do
    action [ :stop, :disable ]
  end

end

service 'ambari-server' do
  action :enable
end

template '/usr/local/bin/update_hdp_repos.sh' do
  source 'update_hdp_repos.sh.erb'
  mode   '0755'
  variables({
    hdp_version:       hdp_version,
    hdp_utils_version: hdp_utils_version,
    ambari_platform:   ambari_platform,
    hdp_platform:      hdp_platform,
    artifacts_uri:     artifacts_uri  
  })
end

execute 'install ambari-bootstrap' do
  command 'git clone https://github.com/seanorama/ambari-bootstrap.git /root/ambari-bootstrap'
  not_if  'test -d /root/ambari-bootstrap'
end

execute 'add NIFI service definition' do
  command "git clone https://github.com/abajwa-hw/ambari-nifi-service.git /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/NIFI"
  not_if "test -d /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/NIFI"
  notifies :restart, 'service[ambari-server]', :delayed
end

execute 'add ZEPPELIN service definition' do
  command "git clone https://github.com/hortonworks-gallery/ambari-zeppelin-service.git /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/ZEPPELIN"
  not_if "test -d /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/ZEPPELIN"
  notifies :restart, 'service[ambari-server]', :delayed
end

execute 'add ZEPPELIN dependencies to roles file' do
  command "sed -i '/dependencies for all/a \    \"ZEPPELIN_MASTER-START\": [\"NAMENODE-START\", \"DATANODE-START\"],' /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/role_command_order.json"
  not_if "grep 'ZEPPELIN_MASTER-START' /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/role_command_order.json >/dev/null"
end

execute 'add OPENTSDB service definition' do
  command "git clone https://github.com/hortonworks-gallery/ambari-opentsdb-service.git /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/OPENTSDB"
  not_if "test -d /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/OPENTSDB"
  notifies :restart, 'service[ambari-server]', :delayed
end

execute 'add FREEIPA service definition' do
  command "git clone https://github.com/hortonworks-gallery/ambari-freeipa-service.git /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/ambari-freeipa-service"
  not_if "test -d /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/ambari-freeipa-service"
  notifies :restart, 'service[ambari-server]', :delayed
end

execute 'add VNCSERVER service definition' do
  command "git clone https://github.com/hortonworks-gallery/ambari-vnc-service.git /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/VNCSERVER"
  not_if "test -d /var/lib/ambari-server/resources/stacks/HDP/#{hdp_version.to_f}/services/VNCSERVER"
  notifies :restart, 'service[ambari-server]', :delayed
end

template '/root/ambari-bootstrap/deploy/create_blueprint.sh' do
  source 'create_blueprint.sh.erb'
  mode   '0755'
  variables({
    ambari_services: standard_services,
    cluster_name: cluster_name
  })
end
