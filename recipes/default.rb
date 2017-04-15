#
# Cookbook Name:: gitlab
# Recipe:: default
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
#

case node['platform_family']
when 'debian'
  include_recipe 'apt'
when 'rhel'
  include_recipe 'yum-epel'
end

# Install new enough git version
include_recipe 'gitlab::git'

# Setup the database connection
case node['gitlab']['database']['type']
when 'mysql'
  include_recipe 'gitlab::mysql'
when 'postgres'
  include_recipe 'gitlab::postgres'
else
  Chef::Log.error "#{node['gitlab']['database']['type']} is not a valid type. Please use 'mysql' or 'postgres'!"
end

# Install SELinux tools where appropriate
extend SELinuxPolicy::Helpers
include_recipe 'selinux_policy::install' if use_selinux

# Install the required packages via cookbook
node['gitlab']['cookbook_dependencies'].each do |requirement|
  include_recipe requirement
end

# Install required packages for Gitlab
package node['gitlab']['packages']

# Add a git user for Gitlab
user node['gitlab']['user'] do
  comment 'Gitlab User'
  home node['gitlab']['home']
  shell '/bin/bash'
  supports manage_home: true
end

# Fix home permissions for nginx
directory node['gitlab']['home'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0755'
end

# Treat gitlab home as regular home for SELinux
selinux_policy_fcontext node['gitlab']['home'] do
  secontext 'user_home_dir_t'
end

# Add the git user to the "gitlab" group
group node['gitlab']['group'] do
  members node['gitlab']['git_user']
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['home']}/.ssh" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0700'
end

file "#{node['gitlab']['home']}/.ssh/authorized_keys" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0600'
end

# Allow SSH connections under SELinux
selinux_policy_fcontext "#{node['gitlab']['home']}/.ssh(/.*)?" do
  secontext 'ssh_home_t'
end

# Allow SSH key generation via /tmp under SELinux
selinux_policy_module 'gitlab-ssh' do
  content <<-EOF
    module gitlab-ssh 0.1;

    require {
      type ssh_keygen_t;
      type initrc_tmp_t;
      class file open;
    }

    allow ssh_keygen_t initrc_tmp_t:file open;
  EOF
end

# Drop off git config
template "#{node['gitlab']['home']}/.gitconfig" do
  source 'gitconfig.erb'
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
end

# Configure gitlab user to auto-accept localhost SSH keys
template "#{node['gitlab']['home']}/.ssh/config" do
  source 'ssh_config.erb'
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  variables(
    fqdn: node['fqdn'],
    trust_local_sshkeys: node['gitlab']['trust_local_sshkeys']
  )
end

# The recommended Ruby is >= 1.9.3
# We'll use Fletcher Nichol's ruby_build cookbook to compile a Ruby.
if node['gitlab']['install_ruby'] !~ /package/
  ruby_build_ruby node['gitlab']['install_ruby'] do
    prefix_path node['gitlab']['install_ruby_path']
    user node['gitlab']['user']
    group node['gitlab']['user']
  end

  # This hack put here to reliably find Ruby
  # cross-platform. Issue #66
  execute 'update-alternatives-ruby' do
    command "update-alternatives --install /usr/local/bin/ruby ruby #{node['gitlab']['install_ruby_path']}/bin/ruby 10"
    not_if { ::File.exist?('/usr/local/bin/ruby') }
  end

  # Install required Ruby Gems for Gitlab with ~git/bin/gem
  %w(charlock_holmes bundler).each do |gempkg|
    gem_package gempkg do
      gem_binary "#{node['gitlab']['install_ruby_path']}/bin/gem"
      action :install
      options('--no-ri --no-rdoc')
    end
  end
else
  # Install required Ruby Gems for Gitlab with system gem
  %w(charlock_holmes bundler).each do |gempkg|
    gem_package gempkg do
      action :install
      options('--no-ri --no-rdoc')
    end
  end
end

# setup gitlab-shell
# Clone Gitlab-shell repo
git node['gitlab']['shell']['home'] do
  repository node['gitlab']['shell']['git_url']
  revision node['gitlab']['shell']['git_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

# Either listen_port has been configured elsewhere or we calculate it
# depending on the https flag
listen_port = \
  node['gitlab']['listen_port'] || (node['gitlab']['https'] ? 443 : 80)

# Address of gitlab api for which gitlab-shell should connect, prefered is
# using custom URL. If prefered URL is defined we are using 'gitlab_host'
# otherwise we just refer back to 'web_fqdn'.
api_fqdn = \
  node['gitlab']['shell']['gitlab_host'] || node['gitlab']['web_fqdn']

# render gitlab-shell config
template node['gitlab']['shell']['home'] + '/config.yml' do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  source 'shell_config.yml.erb'
  variables(
    fqdn: api_fqdn,
    listen_port: listen_port
  )
end

# Clone Gitlab repo from github
git node['gitlab']['app_home'] do
  repository node['gitlab']['git_url']
  revision node['gitlab']['git_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

# Render gitlab init script
# This needs to happen before gitlab.yml is rendered.
# So when the service is subscribed, the init file will be in place
template '/etc/init.d/gitlab' do
  owner 'root'
  group 'root'
  mode '0755'
  source 'gitlab.init.erb'
  variables(
    gitlab_home: node['gitlab']['home'],
    gitlab_app_home: node['gitlab']['app_home'],
    gitlab_user: node['gitlab']['user'],
    gitlab_redis_instance: node['gitlab']['redis_instance']
  )
end

# Write the database.yml
template "#{node['gitlab']['app_home']}/config/database.yml" do
  source 'database.yml.erb'
  owner 'root'
  group node['gitlab']['group']
  mode '0640'
  variables(
    adapter: node['gitlab']['database']['adapter'],
    encoding: node['gitlab']['database']['encoding'],
    collation: node['gitlab']['database']['collation'],
    host: node['gitlab']['database']['host'],
    database: node['gitlab']['database']['database'],
    pool: node['gitlab']['database']['pool'],
    username: node['gitlab']['database']['username'],
    password: node['gitlab']['database']['password']
  )
end

# Render gitlab config file
template "#{node['gitlab']['app_home']}/config/gitlab.yml" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  variables(
    fqdn: node['gitlab']['web_fqdn'] || node['fqdn'],
    https_boolean: node['gitlab']['https'],
    git_user: node['gitlab']['user'],
    git_home: node['gitlab']['home'],
    backup_path: node['gitlab']['backup_path'],
    backup_keep_time: node['gitlab']['backup_keep_time'],
    listen_port: listen_port
  )
end

# Copy file rack_attack.rb
cookbook_file "#{node['gitlab']['app_home']}/config/initializers/rack_attack.rb" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
end

# create log, tmp, pids and sockets directory
%w(log tmp tmp/pids tmp/sockets public/uploads).each do |dir|
  directory File.join(node['gitlab']['app_home'], dir) do
    user node['gitlab']['user']
    group node['gitlab']['group']
    mode '0755'
    recursive true
    action :create
  end
end

# Allow nginx to connect to gitlab.socket under SELinux
selinux_policy_fcontext "#{node['gitlab']['app_home']}/tmp/sockets(/.*)?" do
  secontext 'httpd_var_run_t'
end

selinux_policy_module 'gitlab-nginx-socket' do
  content <<-EOF
    module gitlab-nginx-socket 0.1;

    require {
      type httpd_t;
      type initrc_t;
      class unix_stream_socket connectto;
    }

    allow httpd_t initrc_t:unix_stream_socket connectto;
  EOF
end

# Set SELinux context for log files, necessary for sendmail to work
["#{node['gitlab']['app_home']}/log(/.*)?", "#{node['gitlab']['shell']['home']}/gitlab-shell\\.log.*"].each do |path|
  selinux_policy_fcontext path do
    secontext 'var_log_t'
  end
end

# logrotate gitlab-shell and gitlab
logrotate_app 'gitlab' do
  frequency 'weekly'
  su node['gitlab']['user'] + ' ' + node['gitlab']['group']
  path [
    "#{node['gitlab']['app_home']}/log/*.log",
    "#{node['gitlab']['shell']['home']}/gitlab-shell.log"
  ]
  rotate 52
  options %w(compress delaycompress notifempty copytruncate)
end

# create gitlab-satellites directory
directory File.join(node['gitlab']['home'], 'gitlab-satellites') do
  user node['gitlab']['user']
  group node['gitlab']['group']
  mode '0755'
  recursive true
  action :create
end

# create repositories directory
directory File.join(node['gitlab']['home'], 'repositories') do
  user node['gitlab']['user']
  group node['gitlab']['group']
  mode '2770'
  recursive true
  action :create
end

# create backup_path
directory node['gitlab']['backup_path'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '00755'
  action :create
end

# Render unicorn template
template "#{node['gitlab']['app_home']}/config/unicorn.rb" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  variables(
    fqdn: node['fqdn'],
    gitlab_app_home: node['gitlab']['app_home'],
    gitlab_unicorn_timeout: node['gitlab']['unicorn']['timeout']
  )
end

without_group = node['gitlab']['database']['type'] == 'mysql' ? 'postgres' : 'mysql'

bundler_binary = "#{node['gitlab']['install_ruby_path']}/bin/bundle"
bundle_success = "#{node['gitlab']['app_home']}/vendor/bundle/.success"

# Install Gems with bundle install
execute 'gitlab-bundle-install' do
  command "#{bundler_binary} install --deployment --binstubs --without development test #{without_group} aws && touch #{bundle_success}"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment('LANG' => 'en_US.UTF-8', 'LC_ALL' => 'en_US.UTF-8')
  not_if { File.exist?(bundle_success) }
end

# Install GitLab Workhorse
git "#{node['gitlab']['home']}/gitlab-workhorse" do
  # default repository 'https://gitlab.com/gitlab-org/gitlab-workhorse.git
  repository node['gitlab']['workhorse_repository']
  revision node['gitlab']['workhorse_revision']
  action :sync
  user node['gitlab']['user']
  group node['gitlab']['group']
  notifies :run, 'bash[compile-workhorse]', :immediately
end

bash 'compile-workhorse' do
  action :run
  cwd "#{node['gitlab']['home']}/gitlab-workhorse"
  code <<-EOH
    make
    EOH
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { ::File.exist?("#{node['gitlab']['home']}/gitlab-workhorse/gitlab-workhorse") }
end

nodejs_npm 'gitlab' do
  path node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  options ['--only=production']
  json true
end

# Compile assets
execute 'gitlab-bundle-assets-compile' do
  command "#{bundler_binary} exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production && touch .assets-compiled"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment('LANG' => 'en_US.UTF-8', 'LC_ALL' => 'en_US.UTF-8')
  not_if { File.exist?("#{node['gitlab']['app_home']}/.assets-compiled") }
end

# Initialize database
execute 'gitlab-bundle-rake' do
  # Check the task list below against setup.rake. We can't use
  # gitlab:setup because db:reset DROPs the database and we don't want
  # to give the database user permission to create new databases.
  # https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/tasks/gitlab/setup.rake
  command "#{bundler_binary} exec rake db:schema:load add_limits_mysql setup_postgresql db:seed_fu RAILS_ENV=production && touch .gitlab-setup"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { File.exist?("#{node['gitlab']['app_home']}/.gitlab-setup") }
end

# Use certificate cookbook for keys.
# Look for `search_id` in data_bag `certificates`
certificate_manage 'gitlab' do
  search_id node['gitlab']['certificate_databag_id']
  cert_path '/etc/nginx/ssl'
  owner node['gitlab']['user']
  group node['gitlab']['user']
  nginx_cert true
  not_if { node['gitlab']['certificate_databag_id'].nil? }
  only_if { node['gitlab']['https'] }
end

# Install nginx
include_recipe 'chef_nginx'

# Allow nginx to access static content under SELinux
selinux_policy_fcontext "#{node['gitlab']['app_home']}/public(/.*)?" do
  secontext 'httpd_sys_content_t'
end

# Render and activate nginx default vhost config
template '/etc/nginx/sites-available/gitlab' do
  owner 'root'
  group 'root'
  mode '0644'
  source 'nginx.gitlab.erb'
  notifies :restart, 'service[nginx]'
  variables(
    server_name: node['gitlab']['nginx_server_names'].join(' '),
    hostname: node['hostname'],
    gitlab_app_home: node['gitlab']['app_home'],
    https_boolean: node['gitlab']['https'],
    ssl_certificate: node['gitlab']['ssl_certificate'],
    ssl_certificate_key: node['gitlab']['ssl_certificate_key'],
    ssl_ciphers: node['gitlab']['ssl_ciphers'],
    ssl_protocols: node['gitlab']['ssl_protocols'],
    listen: "#{node['gitlab']['listen_ip']}:#{listen_port}"
  )
end

# Enable gitlab site
nginx_site 'gitlab' do
  enable true
end

# Enable and start unicorn and sidekiq service
service 'gitlab' do
  priority 30
  pattern "unicorn_rails master -D -c #{node['gitlab']['app_home']}/config/unicorn.rb"
  action [:enable, :start]
  subscribes :restart, "template[#{node['gitlab']['app_home']}/config/gitlab.yml]", :delayed
end
