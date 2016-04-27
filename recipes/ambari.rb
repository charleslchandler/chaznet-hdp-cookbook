#
# Cookbook Name:: chaznet-hdp
# Recipe:: ambari-server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

platform = node[:platform]
platform_version = node[:platform_version].to_i

ambari_version = node['ambari']['version']
artifact_uri   = node['artifacts']['base_uri']

case platform
when 'ubuntu'

  ambari_platform = "ubuntu#{platform_version}"

  apt_repository 'ambari' do
    uri "#{artifact_uri}/AMBARI/#{ambari_platform}/#{ambari_version}"
    #uri "http://s3.amazonaws.com/dev.hortonworks.com/ambari/ubuntu12/2.x/BUILDS/#{ambari_version}"
    components ['main']
    distribution 'Ambari'
    key 'B9733A7A07513CAD'
    keyserver 'keyserver.ubuntu.com'
    action :add
    deb_src false
  end

when 'redhat', 'centos'

  ambari_platform = "centos#{platform_version}"

  yum_repository "Updates-ambari-#{ambari_version}" do
    description "ambari-#{ambari_version} - Updates"
    baseurl "#{artifact_uri}/AMBARI/#{ambari_platform}/#{ambari_version}"
    #baseurl "http://public-repo-1.hortonworks.com/ambari/centos$releasever/2.x/updates/#{ambari_version}"
    gpgkey "#{artifact_uri}/AMBARI/#{ambari_platform}/#{ambari_version}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins"
    gpgcheck true
    action :create
    proxy '_none_'
  end  

  service 'firewalld' do
    action [ :stop, :disable ]
  end

end
