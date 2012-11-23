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

# Include cookbook dependencies
%w{ gitlab::gitolite build-essential
    readline sudo openssh xml zlib 
    python::package python::pip }.each do |requirement|
  include_recipe requirement
end

case node['platform_family']
when "rhel"
  include_recipe "yumrepo::epel"
end

# Install required packages for Gitlab
node['gitlab']['packages'].each do |pkg|
  package pkg
end

case node['platform_family']
when "ubuntu","debian"

  # We'll we update the alternatives in orer to use Ruby 1.9.2 instead Ruby 1.8
  bash "Update and set gem alternatives" do
    only_if "test $(update-alternatives --query gem | grep Value | awk '{print $2}') = '/usr/bin/gem1.8'"
    code <<-EOF
rm /usr/bin/ruby

update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.8 180 \
         --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                        /usr/share/man/man1/ruby1.8.1.gz \
        --slave   /usr/bin/ri ri /usr/bin/ri1.8 \
        --slave   /usr/bin/irb irb /usr/bin/irb1.8 \
        --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc1.8

update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 \
         --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                        /usr/share/man/man1/ruby1.9.1.1.gz \
        --slave   /usr/bin/ri ri /usr/bin/ri1.9.1 \
        --slave   /usr/bin/irb irb /usr/bin/irb1.9.1 \
        --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1

update-alternatives --quiet --install /usr/bin/gem gem /usr/bin/gem1.9.1 400 \
            --slave /usr/share/man/man1/gem.1.gz gem.1.gz \
            /usr/share/man/man1/gem1.9.1.1.gz \
            --slave /etc/bash_completion.d/gem bash_completion_gem \
            /etc/bash_completion.d/gem1.9.1 
update-alternatives --set ruby /usr/bin/ruby1.9.1
update-alternatives --set gem /usr/bin/gem1.9.1
exit 0
EOF
  end

  # Install required Ruby Gems for Gitlab

  gem_package("charlock_holmes") do
    gem_binary("/usr/bin/gem1.9.1")
    options("--version '0.6.8'")
  end

  gem_package("bundler") do
    gem_binary("/usr/bin/gem1.9.1")
    options("--bindir /usr/local/bin")
  end

else

  # Include cookbook dependencies
  %w{ ruby_build redisio::install redisio::enable }.each do |requirement|
    include_recipe requirement
  end

  # symlink redis-cli into /usr/bin (needed for gitlab hooks to work)
  link "/usr/bin/redis-cli" do
    to "/usr/local/bin/redis-cli"
  end

  # There are problems deploying on Redhat provided rubies.
  # We'll use Fletcher Nichol's slick ruby_build cookbook to compile a Ruby.
  if node['gitlab']['install_ruby'] !~ /package/
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

  # Install required Ruby Gems for Gitlab
  %w{ charlock_holmes bundler }.each do |gempkg|
    gem_package gempkg do
      action :install
    end
  end
end

# Install sshkey gem into chef
chef_gem "sshkey" do
  action :install
end

# Install pygments from pip
python_pip "pygments" do
  action :install
end

# Add the gitlab user
user node['gitlab']['user'] do
  comment "Gitlab User"
  home node['gitlab']['home']
  shell "/bin/bash"
  supports :manage_home => true
end

# Fix home permissions for nginx
directory node['gitlab']['home'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0755
end

# Add the gitlab user to the "git" group
group node['gitlab']['git_group'] do
  members node['gitlab']['user']
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['home']}/.ssh" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0700
end

# Generate and deploy ssh public/private keys
unless File.exists?("#{node['gitlab']['home']}/.ssh/id_rsa")
  Gem.clear_paths
  require 'sshkey'
  gitlab_sshkey = SSHKey.generate(:type => 'RSA', :comment => "#{node['gitlab']['user']}@#{node['fqdn']}")
  node.set['gitlab']['public_key'] = gitlab_sshkey.ssh_public_key
  node.save unless Chef::Config[:solo]

  # Render private key template
  template "#{node['gitlab']['home']}/.ssh/id_rsa" do
    owner node['gitlab']['user']
    group node['gitlab']['group']
    variables(
      :private_key => gitlab_sshkey.private_key
    )
    mode 0600
  end
end

# Render public key template for gitlab user
template "#{node['gitlab']['home']}/.ssh/id_rsa.pub" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :public_key => node['gitlab']['public_key']
  )
  not_if { File.exists?("#{node['gitlab']['home']}/.ssh/id_rsa.pub") }
end

# Render public key template for gitolite user
template "#{node['gitlab']['git_home']}/gitlab.pub" do
  source "id_rsa.pub.erb"
  owner node['gitlab']['git_user']
  group node['gitlab']['git_group']
  mode 0644
  variables(
    :public_key => node['gitlab']['public_key']
  )
  not_if { File.exists?("#{node['gitlab']['git_home']}/gitlab.pub") }
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

# Sorry for this ugliness.
# It seems maybe something is wrong with the 'gitolite setup' script.
# This was implemented as a workaround.
execute "install-gitlab-key" do
  command "su - #{node['gitlab']['git_user']} -c 'perl #{node['gitlab']['gitolite_home']}/src/gitolite setup -pk #{node['gitlab']['git_home']}/gitlab.pub'"
  user "root"
  cwd node['gitlab']['git_home']
  not_if "grep -q '#{node['gitlab']['user']}' #{node['gitlab']['git_home']}/.ssh/authorized_keys"
end

# Clone Gitlab repo from github
git node['gitlab']['app_home'] do
  repository node['gitlab']['gitlab_url']
  reference node['gitlab']['gitlab_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

directory "#{node['gitlab']['app_home']}/tmp" do
  user node['gitlab']['user']
  group node['gitlab']['group']
  mode "0755"
  action :create
end

# Render gitlab config file
template "#{node['gitlab']['app_home']}/config/gitlab.yml" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :fqdn => node['fqdn'],
    :https_boolean => node['gitlab']['https'],
    :git_user => node['gitlab']['git_user'],
    :git_home => node['gitlab']['git_home'],
    :ldap => node['gitlab']['auth']['ldap']
  )
end

# Link sqlite example config file to database.yml
link "#{node['gitlab']['app_home']}/config/database.yml" do
  to "#{node['gitlab']['app_home']}/config/database.yml.sqlite"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  link_type :hard
end

# Install Gems with bundle install
execute "gitlab-bundle-install" do
  command "bundle install --without development test postgres --deployment"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment({ 'LANG' => "en_US.UTF-8", 'LC_ALL' => "en_US.UTF-8" })
  not_if { File.exists?("#{node['gitlab']['app_home']}/vendor/bundle") }
end

# Setup sqlite database for Gitlab
execute "gitlab-bundle-rake" do
  command "bundle exec rake gitlab:app:setup RAILS_ENV=production"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { File.exists?("#{node['gitlab']['app_home']}/db/production.sqlite3") }
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

# Render unicorn_rails init script
template "/etc/init.d/unicorn_rails" do
  owner "root"
  group "root"
  mode 0755
  source "unicorn_rails.init.erb"
  variables(
    :fqdn => node['fqdn'],
    :gitlab_app_home => node['gitlab']['app_home']
  )
end

# Start unicorn_rails and nginx service
%w{ unicorn_rails nginx }.each do |svc|
  service svc do
    action [ :start, :enable ]
  end
end

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

# Render nginx default vhost config
template "/etc/nginx/conf.d/default.conf" do
  owner "root"
  group "root"
  mode 0644
  source "nginx.default.conf.erb"
  notifies :restart, "service[nginx]"
  variables(
    :hostname => node['hostname'],
    :gitlab_app_home => node['gitlab']['app_home'],
    :https_boolean => node['gitlab']['https'],
    :ssl_certificate => node['gitlab']['ssl_certificate'],
    :ssl_certificate_key => node['gitlab']['ssl_certificate_key']
  )
end
