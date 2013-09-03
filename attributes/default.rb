#
# Cookbook Name:: gitlab
# Attributes:: default
#
# Copyright 2012, Gerald L. Hevener Jr., M.S.
# Copyright 2012, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set attributes for the git user
default['gitlab']['user'] = "git"
default['gitlab']['group'] = "git"
default['gitlab']['home'] = "/home/git"
default['gitlab']['app_home'] = default['gitlab']['home'] + '/gitlab'
default['gitlab']['web_fqdn'] = nil
default['gitlab']['email_from'] = "gitlab@example.com"
default['gitlab']['support_email'] = "support@example.com"

# Set github URL for gitlab
default['gitlab']['git_url'] = "git://github.com/gitlabhq/gitlabhq.git"
default['gitlab']['git_branch'] = "6-0-stable"

# gitlab-shell attributes
default['gitlab']['shell']['home'] = node['gitlab']['home'] + '/gitlab-shell'
default['gitlab']['shell']['git_url'] = "git://github.com/gitlabhq/gitlab-shell.git"
default['gitlab']['shell']['git_branch'] = "v1.7.1"

# Database setup
default['gitlab']['database']['type'] = "mysql"
default['gitlab']['database']['adapter'] = node['gitlab']['database']['type'] == "mysql" ? "mysql2" : "postgresql"
default['gitlab']['database']['encoding'] = node['gitlab']['database']['type'] == "mysql" ? "utf8" : "unicode"
default['gitlab']['database']['host'] = "localhost"
default['gitlab']['database']['pool'] = 5
default['gitlab']['database']['database'] = "gitlab"
default['gitlab']['database']['username'] = "gitlab"

# Required packages for Gitlab
case node['platform']
  when "ubuntu","debian"
    default['gitlab']['packages'] = %w{
    build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev
    libreadline-dev libncurses5-dev libffi-dev curl git-core
    openssh-server redis-server checkinstall libxml2-dev libxslt-dev
    libcurl4-openssl-dev libicu-dev wget python2.7 python-docutils
    ruby1.9.1 ruby1.9.1-dev
  }
  when "redhat","centos","amazon","scientific"
    case node['platform_version'].to_i
      when 5
        default['gitlab']['packages'] = %w{
      curl wget libxslt-devel sqlite-devel openssl-devel
      mysql++-devel libicu-devel glibc-devel libyaml-devel
      python26 python26-devel
    }
      when 6
        default['gitlab']['packages'] = %w{
      curl wget libxslt-devel sqlite-devel openssl-devel
      mysql++-devel libicu-devel glibc-devel
      libyaml-devel python python-devel
    }
    end
  else
    default['gitlab']['packages'] = %w{
    curl wget checkinstall libxslt-dev libsqlite3-dev
    libcurl4-openssl-dev libssl-dev libmysql++-dev
    libicu-dev libc6-dev libyaml-dev python
    python-dev ruby1.9.1 ruby1.9.1-dev
  }
end

# Problems deploying this on RedHat provided rubies.
case node['platform']
  when "redhat","centos","scientific","amazon"
    default['gitlab']['install_ruby'] = "1.9.2-p290"
  else
    default['gitlab']['install_ruby'] = "package"
end

default['gitlab']['trust_local_sshkeys'] = "yes"

default['gitlab']['https'] = false
default['gitlab']['ssl_certificate'] = "/etc/nginx/#{node['fqdn']}.crt"
default['gitlab']['ssl_certificate_key'] = "/etc/nginx/#{node['fqdn']}.key"
default['gitlab']['ssl_req'] = "/C=US/ST=Several/L=Locality/O=Example/OU=Operations/CN=#{node['fqdn']}/emailAddress=root@localhost"

default['gitlab']['backup_path'] = node['gitlab']['app_home'] + "/backups"
default['gitlab']['backup_keep_time'] = 604800

# Ip and port nginx will be serving requests on
default['gitlab']['listen_ip'] = "*"
default['gitlab']['listen_port'] = nil
