puts "WARNING: disabling selinux -- see https://ambari.apache.org/1.2.2/installing-hadoop-using-ambari/content/ambari-chap1-5-5.html"
default['selinux']['state'] = 'disabled'
default['ambari']['standard_services'] = %w( 
  AMBARI_METRICS FLUME HBASE HDFS HIVE KAFKA KNOX OOZIE PIG SLIDER SPARK SQOOP MAPREDUCE2 TEZ YARN ZOOKEEPER NIFI ZEPPELIN
)
