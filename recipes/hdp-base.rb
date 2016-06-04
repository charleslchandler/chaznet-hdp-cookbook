#
# Cookbook Name:: chaznet-hdp
# Recipe:: hdp-base
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

public_ip       = node['public_ip']
fqdn            = "#{node.name}.#{node['dns']['domain_name']}"
platform        = node[:platform]
release_version = node[:platform_version].to_i
artifact_uri    = node[:artifacts][:base_uri]
hdp_version     = node[:hdp][:version]

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
  end

  #yum_repository "HDP-#{hdp_version.to_f}" do
  #  description "HDP-#{hdp_version.to_f}"
  #  baseurl "#{artifact_uri}/HDP/centos$releasever/2.x/updates/#{hdp_version}"
  #  gpgkey "#{artifact_uri}/HDP/centos$releasever/2.x/updates/#{hdp_version}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins"
  #  gpgcheck true
  #  action :create
  #  proxy '_none_'
  #end

  #yum_repository "HDP-UTILS" do
  #  description "HDP-UTILS-1.1.0.20"
  #  baseurl "#{artifact_uri}/HDP-UTILS-1.1.0.20/repos/centos$releasever"
  #  gpgkey "#{artifact_uri}/HDP-UTILS-1.1.0.20/repos/centos$releasever/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins"
  #  gpgcheck true
  #  action :create
  #  proxy '_none_'
  #end

  cookbook_file '/etc/sudoers.d/888-dont-requiretty' do
    source 'sudoers-888-dont-requiretty'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

when 'ubuntu', 'deban'
  defrag_filename_path = '/sys/kernel/mm/transparent_hugepage/defrag'

  #apt_repository "HDP-#{hdp_version.to_f}" do
  #  uri "#{artifact_uri}/HDP/ubuntu14/2.x/updates/#{hdp_version}"
  #  components ['main']
  #  distribution 'Ambari'
  #  key 'B9733A7A07513CAD'
  #  keyserver 'keyserver.ubuntu.com'
  #  action :add
  #  deb_src false
  #end

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

template '/etc/hostname' do
  source 'hostname.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({hostname: fqdn})
  action :create
end

execute 'ensure hostname is in /etc/hosts' do
  command "echo '#{node[:ipaddress]} #{fqdn} #{node.name}' >> /etc/hosts"
  not_if "grep '^#{node[:ipaddress]} #{fqdn}' /etc/hosts"
end

execute 'ensure public IP is in /etc/hosts' do
  command "echo '#{public_ip} #{fqdn} #{node.name}' >> /etc/hosts"
  not_if "grep '^#{public_ip} #{fqdn}' /etc/hosts"
end

template '/etc/sysconfig/network' do
  source 'sysconfig-network.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({hostname: fqdn})
  action :create
end

service 'iptables' do
  action [:stop, :disable]
end

service 'ip6tables' do
  action [:stop, :disable]
end
