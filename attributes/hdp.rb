puts "WARNING: disabling selinux -- see https://ambari.apache.org/1.2.2/installing-hadoop-using-ambari/content/ambari-chap1-5-5.html"
default['selinux']['state'] = 'disabled'
