puts "WARNING: disabling selinux -- see https://ambari.apache.org/1.2.2/installing-hadoop-using-ambari/content/ambari-chap1-5-5.html"
default['selinux']['state'] = 'disabled'
default['hdp']['mysql_java_connector']['version'] = '5.1.40'
default['hdp']['mysql_java_connector']['sha256']  = '83232082a005492a0f01678d08d5426afae716af2d47e799e06444e1a9db6350'
