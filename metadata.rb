maintainer 'Eric G. Wolfe'
maintainer_email 'eric.wolfe@gmail.com'
license 'Apache 2.0'
description 'Installs/Configures gitlab'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
name 'gitlab'
version '6.9.0'

depends 'redisio', '>= 2.1.0'

%w(build-essential zlib readline ncurses git openssh xml
   ruby_build certificate database logrotate mysql nginx
   postgresql apt yum-epel).each do |cb_depend|
  depends cb_depend
end

%w(redhat centos scientific amazon debian ubuntu).each do |os|
  supports os
end
