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
default['gitlab']['user'] = "gitlab"
default['gitlab']['group'] = "gitlab"
default['gitlab']['home'] = "/var/gitlab"
default['gitlab']['app_home'] = "#{node['gitlab']['home']}/gitlab"

# Set github URL for gitlab
default['gitlab']['gitlab_url'] = "git://github.com/gitlabhq/gitlabhq.git"
default['gitlab']['gitlab_branch'] = "master"

# Required packages for Gitlab
case node['platform']
when "ubuntu","debian"
  default['gitlab']['packages'] = %w{
    ruby1.9.1 ruby1.9.1-dev ri1.9.1 libruby1.9.1
    curl wget checkinstall libxslt-dev libsqlite3-dev
    libcurl4-openssl-dev libssl-dev libmysql++-dev
    libicu-dev libc6-dev libyaml-dev nginx python python-dev
  }
when "redhat","centos","amazon","scientific"
  case node['platform_version'].to_i
  when 5
    default['gitlab']['packages'] = %w{
      curl wget libxslt-devel sqlite-devel openssl-devel
      mysql++-devel libicu-devel glibc-devel libyaml-devel
      nginx python26 python26-devel
    }
  when 6
    default['gitlab']['packages'] = %w{
      curl wget libxslt-devel sqlite-devel openssl-devel
      mysql++-devel libicu-devel glibc-devel
      libyaml-devel nginx python python-devel
    }
  end
else
  default['gitlab']['packages'] = %w{
    ruby1.9.1 ruby1.9.1-dev ri1.9.1 libruby1.9.1
    curl wget checkinstall libxslt-dev libsqlite3-dev
    libcurl4-openssl-dev libssl-dev libmysql++-dev
    libicu-dev libc6-dev libyaml-dev nginx python
    python-dev
  }
end

default['gitlab']['trust_local_sshkeys'] = "yes"

# Problems deploying this on RedHat provided rubies. 
case node['platform']
when "redhat","centos","scientific","amazon"
  default['gitlab']['install_ruby'] = "1.9.2-p290"
else
  default['gitlab']['install_ruby'] = "package"
end
