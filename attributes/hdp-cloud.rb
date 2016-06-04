default['public_ip'] = %x(curl http://169.254.169.254/2009-04-04/meta-data/public-ipv4).chomp
