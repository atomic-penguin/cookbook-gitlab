maintainer       "Gerald L. Hevener Jr., M.S."
maintainer_email "hevenerg@marshall.edu"
license          "Apache 2.0"
description      "Installs/Configures gitlab"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
name             "gitlab"
version          "0.3.4"
%w{ gitolite }.each do |cb_conflict|
  conflicts cb_conflict
end
%w{ yumrepo ruby_build git redisio build-essential python readline sudo nginx openssh perl xml zlib}.each do |cb_depend|
  depends cb_depend
end
%w{ redhat centos scientific amazon debian ubuntu }.each do |os|
  supports os
end
