maintainer       'Eric G. Wolfe'
maintainer_email 'eric.wolfe@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures gitlab'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
name             'gitlab'
version          '6.4.1'

%w[ build-essential zlib readline ncurses git openssh redisio xml
    ruby_build certificate database logrotate mysql nginx
    postgresql apt ].each do |cb_depend|
  depends cb_depend
end

depends 'nginx', '<= 2.0.8'
depends 'yum', '<= 2.4.4'

%w[ redhat centos scientific amazon debian ubuntu ].each do |os|
  supports os
end
