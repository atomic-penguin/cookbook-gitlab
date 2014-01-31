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
  include_recipe 'yum::epel'
end

# Setup the database
case node['gitlab']['database']['type']
when 'mysql'
  include_recipe 'gitlab::mysql'
when 'postgres'
  include_recipe 'gitlab::postgres'
else
  Chef::Log.error "#{node['gitlab']['database']['type']} is not a valid type. Please use 'mysql' or 'postgres'!"
end

# Install the required packages via cookbook
node['gitlab']['cookbook_dependencies'].each do |requirement|
  include_recipe requirement
end

# Install required packages for Gitlab
node['gitlab']['packages'].each do |pkg|
  package pkg
end

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

  # Install required Ruby Gems for Gitlab with ~git/bin/gem
  %w[charlock_holmes bundler].each do |gempkg|
    gem_package gempkg do
      gem_binary "#{node['gitlab']['install_ruby_path']}/bin/gem"
      action :install
      options('--no-ri --no-rdoc')
    end
  end
else
# Install required Ruby Gems for Gitlab with system gem
  %w[charlock_holmes bundler].each do |gempkg|
    gem_package gempkg do
      gem_binary "#{node['gitlab']['install_ruby_path']}/bin/gem"
      action :install
      options('--no-ri --no-rdoc')
    end
  end
end

# setup gitlab-shell
# Clone Gitlab-shell repo
git node['gitlab']['shell']['home'] do
  repository node['gitlab']['shell']['git_url']
  reference node['gitlab']['shell']['git_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

# Either listen_port has been configured elsewhere or we calculate it depending on the https flag
listen_port = node['gitlab']['listen_port'] || (node['gitlab']['https'] ? 443 : 80)

# render gitlab-shell config
template node['gitlab']['shell']['home'] + '/config.yml' do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  source 'shell_config.yml.erb'
  variables(
      fqdn: node['gitlab']['web_fqdn'] || node['fqdn'],
      listen: listen_port
  )
end

# Clone Gitlab repo from github
git node['gitlab']['app_home'] do
  repository node['gitlab']['git_url']
  reference node['gitlab']['git_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

# Write the database.yml
template "#{node['gitlab']['app_home']}/config/database.yml" do
  source 'database.yml.erb'
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  variables(
      adapter: node['gitlab']['database']['adapter'],
      encoding: node['gitlab']['database']['encoding'],
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
      backup_keep_time: node['gitlab']['backup_keep_time']
  )
end

# Copy file rack_attack.rb
cookbook_file "#{node['gitlab']['app_home']}/config/initializers/rack_attack.rb" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
end

# create log, tmp, pids and sockets directory
%w{ log tmp tmp/pids tmp/sockets public/uploads }.each do |dir|
  directory File.join(node['gitlab']['app_home'], dir) do
    user node['gitlab']['user']
    group node['gitlab']['group']
    mode '0755'
    recursive true
    action :create
  end
end

# logrotate gitlab-shell and gitlab
logrotate_app 'gitlab' do
  frequency 'weekly'
  path ["#{node['gitlab']['app_home']}/log/*.log",
        "#{node['gitlab']['shell']['home']}/gitlab-shell.log"]
  rotate 52
  options %w[compress delaycompress notifempty copytruncate]
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
      gitlab_app_home: node['gitlab']['app_home']
  )
end

without_group = node['gitlab']['database']['type'] == 'mysql' ? 'postgres' : 'mysql'

bundler_binary = "#{node['gitlab']['install_ruby_path']}/bin/bundle"
bundle_success = "#{node['gitlab']['app_home']}/vendor/bundle/.success"

# Install Gems with bundle install
execute 'gitlab-bundle-install' do
  command "#{bundler_binary} install --deployment --without development test #{without_group} aws && touch #{bundle_success}"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment('LANG' => 'en_US.UTF-8', 'LC_ALL' => 'en_US.UTF-8')
  not_if { File.exists?(bundle_success) }
end

# Precompile assets
execute 'gitlab-bundle-precompile-assets' do
  command "#{bundler_binary} exec rake assets:precompile RAILS_ENV=production"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment('LANG' => 'en_US.UTF-8', 'LC_ALL' => 'en_US.UTF-8')
  only_if { Dir["#{node['gitlab']['app_home']}/public/assets/*"].empty? }
end

# Initialize database
execute 'gitlab-bundle-rake' do
  command "#{bundler_binary} exec rake gitlab:setup RAILS_ENV=production force=yes && touch .gitlab-setup"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { File.exists?("#{node['gitlab']['app_home']}/.gitlab-setup") }
end

# Render gitlab init script
template '/etc/init.d/gitlab' do
  owner 'root'
  group 'root'
  mode '0755'
  source 'gitlab.init.erb'
  variables(
      gitlab_app_home: node['gitlab']['app_home'],
      gitlab_user: node['gitlab']['user']
  )
end

# Use certificate cookbook for keys
certificate_manage node['gitlab']['certificate_databag_id'] do
  cert_path '/etc/nginx/ssl'
  owner node['gitlab']['user']
  group node['gitlab']['user']
  nginx_cert true
  only_if { node['gitlab']['https'] && !node['gitlab']['certificate_databag_id'].nil? }
end

# Create nginx directories before dropping off templates
include_recipe 'nginx::commons_dir'

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
      listen: "#{node['gitlab']['listen_ip']}:#{listen_port}"
  )
end

# Install nginx
include_recipe 'nginx'

# Enable gitlab site
nginx_site 'gitlab' do
  enable true
end

# Disable default site
nginx_site 'default' do
  enable false
end

# Enable and start unicorn and sidekiq service
service 'gitlab' do
  pattern "unicorn_rails master -D -c #{node['gitlab']['app_home']}/config/unicorn.rb"
  action [:enable, :start]
  subscribes :restart, "template[#{node['gitlab']['app_home']}/config/gitlab.yml]", :delayed
end
