#
# Cookbook Name:: gitlab
# Attributes:: default
#
# Copyright 2012, Gerald L. Hevener Jr., M.S.
# Copyright 2012, Eric G. Wolfe
# Copyright 2013, Johannes Becker
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
default['gitlab']['user'] = 'git'
default['gitlab']['group'] = 'git'
default['gitlab']['home'] = '/srv/git'
default['gitlab']['app_home'] = default['gitlab']['home'] + '/gitlab'
default['gitlab']['web_fqdn'] = nil
default['gitlab']['nginx_server_names'] = ['gitlab.*', node['fqdn']]
default['gitlab']['email_from'] = "gitlab@#{node['domain']}"
default['gitlab']['support_email'] = "gitlab-support@#{node['domain']}"

# User default privileges
default['gitlab']['default_projects_limit'] = 10
default['gitlab']['default_can_create_group'] = true
default['gitlab']['username_changing_enabled'] = true

# Set github URL for gitlab
default['gitlab']['git_url'] = 'git://github.com/gitlabhq/gitlabhq.git'
default['gitlab']['git_branch'] = '7-7-stable'

# gitlab-shell attributes
default['gitlab']['shell']['home'] = node['gitlab']['home'] + '/gitlab-shell'
default['gitlab']['shell']['git_url'] = 'git://github.com/gitlabhq/gitlab-shell.git'
default['gitlab']['shell']['git_branch'] = 'v2.4.1'

# Database setup
default['gitlab']['database']['type'] = 'mysql'
default['gitlab']['database']['adapter'] = node['gitlab']['database']['type'] == 'mysql' ? 'mysql2' : 'postgresql'
default['gitlab']['database']['encoding'] = node['gitlab']['database']['type'] == 'mysql' ? 'utf8' : 'unicode'
default['gitlab']['database']['host'] = 'localhost'
default['gitlab']['database']['pool'] = 5
default['gitlab']['database']['database'] = 'gitlab'
default['gitlab']['database']['username'] = 'gitlab'
default['gitlab']['database']['userhost'] = 'localhost'

# Ruby setup
include_attribute 'ruby_build'
default['ruby_build']['upgrade'] = 'sync'
default['gitlab']['install_ruby'] = '1.9.3-p484'
default['gitlab']['install_ruby_path'] = node['gitlab']['home']
default['gitlab']['cookbook_dependencies'] = %w(
  zlib readline ncurses openssh
  logrotate redisio::install redisio::configure redisio::enable ruby_build
)

# Required packages for Gitlab
case node['platform_family']
when 'debian'
  default['gitlab']['packages'] = %w(
    libyaml-dev libssl-dev libgdbm-dev libffi-dev checkinstall
    curl libcurl4-openssl-dev libicu-dev wget python-docutils sudo
    cmake libkrb5-dev pkg-config
  )
when 'rhel'
  default['gitlab']['packages'] = %w(
    libyaml-devel openssl-devel gdbm-devel libffi-devel
    curl libcurl-devel libicu-devel wget python-docutils sudo
    cmake libkrb5-dev pkgconfig
  )
else
  default['gitlab']['install_ruby'] = 'package'
  default['gitlab']['cookbook_dependencies'] = %w(
    openssh readline zlib ruby_build
    redisio::install redisio::configure redisio::enable
  )
  default['gitlab']['packages'] = %w(
    autoconf binon flex gcc gcc-c++ make m4
    git
    zlib1g-dev libyaml-dev libssl-dev libgdbm-dev
    libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server
    redis-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev
    libicu-dev python-docutils sudo cmake libkrb5-dev pkg-config
  )
end

default['gitlab']['trust_local_sshkeys'] = 'yes'

default['gitlab']['https'] = false
default['gitlab']['certificate_databag_id'] = nil
default['gitlab']['self_signed_cert'] = false
default['gitlab']['ssl_certificate'] = "/etc/nginx/ssl/certs/#{node['fqdn']}.pem"
default['gitlab']['ssl_certificate_key'] = "/etc/nginx/ssl/private/#{node['fqdn']}.key"

default['gitlab']['backup_path'] = node['gitlab']['app_home'] + '/backups'
default['gitlab']['backup_keep_time'] = 604_800

# Ip and port nginx will be serving requests on
default['gitlab']['listen_ip'] = '*'
default['gitlab']['listen_port'] = nil

# LDAP authentication
default['gitlab']['ldap']['enabled'] = false
default['gitlab']['ldap']['host'] = '_your_ldap_server'
default['gitlab']['ldap']['base'] = '_the_base_where_you_search_for_users'
default['gitlab']['ldap']['port'] = 636
default['gitlab']['ldap']['uid'] = 'sAMAccountName'
default['gitlab']['ldap']['method'] = 'ssl'
default['gitlab']['ldap']['bind_dn'] = '_the_full_dn_of_the_user_you_will_bind_with'
default['gitlab']['ldap']['password'] = '_the_password_of_the_bind_user'
default['gitlab']['ldap']['allow_username_or_email_login'] = true

# Gravatar
default['gitlab']['gravatar']['enabled'] = true
