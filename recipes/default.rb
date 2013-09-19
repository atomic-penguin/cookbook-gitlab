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

node['gitlab']['cookbook_dependencies'].each do |requirement|  
  include_recipe requirement
end

# symlink redis-cli into /usr/bin (needed for gitlab hooks to work)
link "/usr/bin/redis-cli" do
  to "/usr/local/bin/redis-cli"
end

# The vendor recommended Ruby is >= 2.0.0 
# We'll use Fletcher Nichol's slick ruby_build cookbook to compile a Ruby.
if node['gitlab']['install_ruby'] !~ /package/
  # build ruby
  ruby_build_ruby node['gitlab']['install_ruby']

  # Drop off a profile script.
  template "/etc/profile.d/gitlab.sh" do
    owner "root"
    group "root"
    mode 0755
    variables(
        :fqdn => node['fqdn'],
        :install_ruby => node['gitlab']['install_ruby']
    )
  end

  # Set PATH for remainder of recipe.
  ENV['PATH'] = "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/ruby/#{node['gitlab']['install_ruby']}/bin"
end

user node['gitlab']['user'] do
  comment "Gitlab User"
  home node['gitlab']['home']
  shell "/bin/bash"
  supports :manage_home => true
end

template "#{node['gitlab']['home']}/.gitconfig" do
  source "gitconfig.erb"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
end

# Install required packages for Gitlab
node['gitlab']['packages'].each do |pkg|
  package pkg
end

# Install sshkey gem into chef
chef_gem "sshkey" do
  action :install
end

# Install required Ruby Gems for Gitlab
%w[ charlock_holmes ].each do |gempkg|
  gem_package gempkg do
    action :install
  end
end

# Fix home permissions for nginx
directory node['gitlab']['home'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0755
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['home']}/.ssh" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0700
end

# Configure gitlab user to auto-accept localhost SSH keys
template "#{node['gitlab']['home']}/.ssh/config" do
  source "ssh_config.erb"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
      :fqdn => node['fqdn'],
      :trust_local_sshkeys => node['gitlab']['trust_local_sshkeys']
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

# create gitlab-satellites directory
directory File.join(node['gitlab']['home'], "gitlab-satellites") do
  user node['gitlab']['user']
  group node['gitlab']['group']
  mode "0755"
  recursive true
  action :create
end

# create repositories directory
directory File.join(node['gitlab']['home'], "repositories") do
  user node['gitlab']['user']
  group node['gitlab']['group']
  mode "2770"
  recursive true
  action :create
end

# create log, tmp, pids and sockets directory
%w{ log tmp tmp/pids tmp/sockets public/uploads }.each do |dir|
  directory File.join(node['gitlab']['app_home'], dir) do
    user node['gitlab']['user']
    group node['gitlab']['group']
    mode "0755"
    recursive true
    action :create
  end
end

# create backup_path
directory node['gitlab']['backup_path'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 00755
  action :create
end

# Render gitlab config file
template "#{node['gitlab']['app_home']}/config/gitlab.yml" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
      :fqdn => node['gitlab']['web_fqdn'] || node['fqdn'],
      :https_boolean => node['gitlab']['https'],
      :git_user => node['gitlab']['user'],
      :git_home => node['gitlab']['home'],
      :backup_path => node['gitlab']['backup_path'],
      :backup_keep_time => node['gitlab']['backup_keep_time']
  )
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


# Write the database.yml
template "#{node['gitlab']['app_home']}/config/database.yml" do
  source 'database.yml.erb'
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  variables(
      :adapter  => node['gitlab']['database']['adapter'],
      :encoding => node['gitlab']['database']['encoding'],
      :host     => node['gitlab']['database']['host'],
      :database => node['gitlab']['database']['database'],
      :pool     => node['gitlab']['database']['pool'],
      :username => node['gitlab']['database']['username'],
      :password => node['gitlab']['database']['password']
  )
end

without_group = node['gitlab']['database']['type'] == 'mysql' ? 'postgres' : 'mysql'

# Install Gems with bundle install
execute "gitlab-bundle-install" do
  command "bundle install --without development test #{without_group} --deployment"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment({ 'LANG' => "en_US.UTF-8", 'LC_ALL' => "en_US.UTF-8" })
  not_if { File.exists?("#{node['gitlab']['app_home']}/vendor/bundle") }
end

# Setup sqlite database for Gitlab
execute "gitlab-bundle-rake" do
  command "bundle exec rake gitlab:setup RAILS_ENV=production force=yes && touch .gitlab-setup"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { File.exists?("#{node['gitlab']['app_home']}/.gitlab-setup") }
end

# Render unicorn template
template "#{node['gitlab']['app_home']}/config/unicorn.rb" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
      :fqdn => node['fqdn'],
      :gitlab_app_home => node['gitlab']['app_home']
  )
end

# Render gitlab init script
template "/etc/init.d/gitlab" do
  owner "root"
  group "root"
  mode 0755
  source "gitlab.init.erb"
  variables(
      :gitlab_app_home => node['gitlab']['app_home'],
      :gitlab_user => node['gitlab']['user']
  )
end

# generate ssl keys for nginx
bash "Create SSL key" do
  not_if { ! node['gitlab']['https'] || File.exists?(node['gitlab']['ssl_certificate_key']) }
  cwd "/etc/nginx"
  code <<-EOF
umask 077
openssl genrsa 2048 > #{node['gitlab']['ssl_certificate_key']}
  EOF
end

bash "Create SSL certificate" do
  not_if { ! node['gitlab']['https'] || File.exists?(node['gitlab']['ssl_certificate']) }
  cwd "/etc/nginx"
  code "openssl req -subj \"#{node['gitlab']['ssl_req']}\" -new -x509 -nodes -sha1 -days 3650 -key #{node['gitlab']['ssl_certificate_key']} > #{node['gitlab']['ssl_certificate']}"
end

# Deactivate the nginx default site
node.default['nginx']['default_site_enabled'] = false

# Either listen_port has been configured elsewhere or we calculate it depending on the https flag
listen_port = node['gitlab']['listen_port'] || node['gitlab']['https'] ? 443 : 80

# Render and activate nginx default vhost config
template "/etc/nginx/sites-available/gitlab.conf" do
  owner "root"
  group "root"
  mode 0644
  source "nginx.gitlab.conf.erb"
  notifies :restart, "service[nginx]"
  variables(
      :hostname => node['hostname'],
      :gitlab_app_home => node['gitlab']['app_home'],
      :https_boolean => node['gitlab']['https'],
      :ssl_certificate => node['gitlab']['ssl_certificate'],
      :ssl_certificate_key => node['gitlab']['ssl_certificate_key'],
      :listen => "#{node['gitlab']['listen_ip']}:#{listen_port}"
  )
end
nginx_site 'gitlab.conf'

# setup gitlab-shell
# Clone Gitlab-shell repo
git node['gitlab']['shell']['home'] do
  repository node['gitlab']['shell']['git_url']
  reference node['gitlab']['shell']['git_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

# render gitlab-shell config
template node['gitlab']['shell']['home'] + "/config.yml" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  source "shell_config.yml.erb" 
  variables(
      :fqdn => node['gitlab']['web_fqdn'] || node['fqdn']
  )
end 

# enable gitlab on boot
execute "update-rc.d-gitlab" do
  command "update-rc.d gitlab defaults 21"
end

# Enable and start unicorn_rails and nginx service
%w{ gitlab nginx }.each do |svc|
  service svc do
    action [ :enable, :start ]
  end
end
