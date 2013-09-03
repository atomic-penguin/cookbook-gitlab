maintainer       "Johannes Becker"
maintainer_email "jb@jbecker.it"
license          "Apache 2.0"
description      "Installs/Configures gitlab"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
name             "gitlab"
version          "0.6.0"
%w{ nginx }.each do |cb_conflict|
  conflicts cb_conflict
end
%w{ yumrepo ruby_build git redisio build-essential python readline sudo nginx openssh perl xml zlib database mysql postgresql }.each do |cb_depend|
  depends cb_depend
end
%w{ redhat centos scientific amazon debian ubuntu }.each do |os|
  supports os
end
