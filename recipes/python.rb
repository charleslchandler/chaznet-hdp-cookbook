#
# Cookbook Name:: chaznet-hdp
# Recipe:: python
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require_recipe 'chaznet-base::development-python'

python_runtime '2' do
  options pip_version: true
end

platform = node[:platform]

case platform
when 'ubuntu'

  package 'freetype-dev'
  package 'libpng-devel'
  package 'lapack-dev'

when 'redhat', 'centos'

  package 'freetype-devel'
  package 'libpng-devel'
  package 'lapack-devel'

end

%w(numpy scipy pandas scikit-learn tornado pyzmq pygments matplotlib jinja2 jsonschema).each do |pkg|
  python_package pkg
end

python_package 'jupyter'
