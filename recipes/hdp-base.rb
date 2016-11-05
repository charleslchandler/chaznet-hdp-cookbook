#
# Cookbook Name:: chaznet-hdp
# Recipe:: hdp-base
#
# Copyright (c) 2016 Chaz Chandler, All Rights Reserved.

public_ip       = node['public_ip']
domain          = node['dns']['domain_name']
fqdn            = "#{node.name}.#{domain}"
platform        = node[:platform]
release_version = node[:platform_version].to_i
artifacts_uri   = node[:artifacts][:base_uri]
hdp_version     = node[:hdp][:version]
mjc_version     = node[:hdp][:mysql_java_connector][:version]

require_recipe 'chaznet-base::development-java'

case platform
when 'redhat', 'centos'
  require_recipe 'selinux::disabled'

  defrag_filename_path = if release_version == 6
    '/sys/kernel/mm/redhat_transparent_hugepage/defrag'
  else
    '/sys/kernel/mm/transparent_hugepage/defrag'
  end

  if release_version == 7

    service 'firewalld' do
      action [:stop, :disable]
    end

    sysctl_ipv6_disabler = '/etc/sysctl.d/99-hadoop-ipv6.conf'
    cookbook_file sysctl_ipv6_disabler do
      source 'sysctl-99-hadoop-ipv6.conf'
      owner 'root'
      group 'root'
      mode '0644'
      action :create
    end

    execute 'disable IPv6 now' do
      command "/sbin/sysctl -e -p #{sysctl_ipv6_disabler}"
    end

  elsif release_version == 6

    link '/etc/init.d/mysqld' do
      to '/etc/init.d/mysql'
      not_if 'test -e /etc/init.d/mysqld'
      only_if 'test -e /etc/init.d/mysql'
    end

  end

  cookbook_file '/etc/sudoers.d/888-dont-requiretty' do
    source 'sudoers-888-dont-requiretty'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  remote_file "/usr/share/java/mysql-connector-java-#{mjc_version}-bin.jar" do
    source   "#{artifacts_uri}/java/mysql-connector-java-#{mjc_version}-bin.jar"
    checksum node[:hdp][:mysql_java_connector][:sha256]
  end

  link '/usr/share/java/mysql-connector-java.jar' do
    to "/usr/share/java/mysql-connector-java-#{mjc_version}-bin.jar"
  end

when 'ubuntu', 'deban'
  defrag_filename_path = '/sys/kernel/mm/transparent_hugepage/defrag'

end

%w(haveged curl ntp openssl python zlib wget unzip openssh-clients).each do |pkg|
  package pkg
end

# see http://blog.cloudera.com/blog/2015/01/how-to-deploy-apache-hadoop-clusters-like-a-boss/
execute 'disable transparent huge pages (THP)' do
  command "echo 'never' > #{defrag_filename_path}"
end

execute 'persist disablement of THP' do
  command "echo \"echo 'never' > #{defrag_filename_path}\" >> /etc/rc.local"
  not_if "grep \"echo 'never' > #{defrag_filename_path}\" /etc/rc.local"
end

execute 'ensure hostname is in /etc/hosts' do
  command "echo '#{node[:ipaddress]} #{fqdn} #{node.name}' >> /etc/hosts"
  not_if "grep '^#{node[:ipaddress]} #{fqdn}' /etc/hosts"
end

execute 'ensure public IP is in /etc/hosts' do
  command "echo '#{public_ip} #{fqdn} #{node.name}' >> /etc/hosts"
  not_if "grep '^#{public_ip} #{fqdn}' /etc/hosts"
end

execute 'set hostname now' do
  command "hostname '#{node.name}' && domainname '#{domain}'"
  not_if "hostname -f | grep '^#{fqdn}$'"
end

template '/etc/cloud/cloud.cfg.d/99_hostname.cfg' do
  source 'etc-cloud-cloud.cfg.d-99_hostname.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    hostname: node.name,
    fqdn: fqdn
  })
  action :create
end

service 'iptables' do
  action [:stop, :disable]
end

service 'ip6tables' do
  action [:stop, :disable]
end

service 'haveged' do
  action [:enable, :start]
end

require_recipe 'chaznet-hdp::accumulo'
