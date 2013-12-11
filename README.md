## Description

This cookbook will deploy gitlab; a free project and repository management
application.

Gitlab code hosted on github [here](https://github.com/gitlabhq/gitlabhq/tree/stable).

## Important changes

Going forward, the cookbook major version (i.e. 6.1.x) will target the
matching stable branch (i.e. 6-1-stable) of the Gitlab application.
The 6.1.x release is not backwards compatible with previous versions targeting
Gitlab master.

For the initial 6.1.x release of the cookbook, the default Ruby will
be 1.9.3 compiled with [ruby_build](http://fnichol.github.com/chef-ruby_build/).
Using a compiled 1.9.3 Ruby follows the Gitlab installation guidelines upstream.
If you have a better approach which reduced complexity or reduces converge time, 
please open a pull request on Github.

The application home has moved from `/var/gitlab/gitlab` to `/srv/git/gitlab`
in accordance with the [Filesystem Hierarchy Standard (FHS) version 2.3](http://www.pathname.com/fhs/).

## Requirements
============

* Hard disk space
  - About 300 Mb, plus enough space for repositories in application home 

## Cookbook dependencies
============

* [ruby\_build](http://fnichol.github.com/chef-ruby_build/)
  - Thanks to Fletcher Nichol for his awesome ruby\_build cookbook.
    This ruby\_build LWRP is used to build Ruby 1.9.3 for gitlab.

* [redisio](http://ckbk.it/redisio)
  - Thanks to Brian Bianco for this Redis cookbook.

* Opscode, Inc cookbooks
  - [git](http://ckbk.it/git)
  - [build-essential](http://ckbk.it/build-essential)
  - [python](http://ckbk.it/python)
  - [sudo](http://ckbk.it/sudo)
  - [nginx](http://ckbk.it/nginx)
  - [openssh](http://ckbk.it/openssh)
  - [perl](http://ckbk.it/perl)
  - [xml](http://ckbk.it/xml)
  - [zlib](http://ckbk.it/zlib)
  - [database](http://ckbk.it/database)


Attributes
==========

* `gitlab['user']` & `gitlab['group']`
  - Gitlab service user and group for Unicorn Rails app, default `git`

* `gitlab['home']`
  - Gitlab top-level home for service account, default `/srv/git`

* `gitlab['app_home']`
  - Gitlab application home, default `/srv/git/gitlab`

* `gitlab['email_from']`
  - Gitlab email from, default `gitlab@ + node.fqdn`

* `gitlab['support_email']`
  - Gitlab support email, default `gitlab-support@ + node.fqdn`

* `gitlab['git_url']`
  - Github gitlab address, default git://github.com/gitlabhq/gitlabhq.git

* `gitlab['git_branch']`
  - Defaults to stable GitlabHQ branch matching the major version of this cookbook. e.g. 6.1.x => 6-1-stable

* `gitlab['packages']`
  - Platform specific OS packages

* `gitlab['trust_local_sshkeys']`
  - `ssh_config` key for gitlab to trust localhost keys automatically, default yes

* `gitlab['install_ruby']`
  - Attribute to determine whether vendor packages are installed,
    or Rubies are built, defaults 1.9.3 for Debian and RHEL family platforms.
  - If you choose to use a vendor provided package, you will need to use
    a role to override the `gitlab['packages']` array.

* `gitlab['https']`
  - Whether https should be used, default false

* `gitlab['certificate_databag_id']`
  - Encrypted databag name containing certificate file, CA bundle, and key. Default nil
  - See [certificate cookbook](http://ckbk.it/certificate) for further information.

* `gitlab['backup_path']`
  - Path in file system where backups are stored. Default `gitlab['app_home'] + backups/`

* `gitlab['backup_keep_time']`
  - Units are seconds. Older backups will automatically be deleted when new backup is created. Set to 0 to keep backups forever.
  - Defaults to 604800

* `gitlab['listen_ip']`
  - IP address that nginx will listen on, default `*` (listen on all IPs)

* `gitlab['listen_port']`
  - Port that nginx will listen on, default to 80 if gitlab['https'] is set to false, 443 if set to true

* `gitlab['web_fqdn']`
  - An overridable service name, used in gitlab and unicorn configuration files.
    Useful if `hostname -f` is not the same as the customer facing hostname.
    Default is unset. Effective default is node['fqdn']

* `gitlab['nginx_server_names']`
  - An array with nginx `server_name` matches.  Helpful to override default test site pages
    shipping with some nginx packages.  Default `[ 'gitlab.*', node['fqdn'] ]`.
    See [nginx server_name documentation](http://nginx.org/en/docs/http/server_names.html)
    for valid matching patterns.

* gitlab['gravatar']['enabled']
  - Use Gravatar to fetch user avatars 
  - Options: "true", "false"
  - Default "true"

### Database Attributes

**Note**, most of the database attributes have sane defaults. You will only need to change these configuration options if
you're using a non-standard installation. Please see `attributes/default.rb` for more information on how a dynamic attribute
is calculated.

* gitlab['database']['type']
  - The database (datastore) to use.
  - Options: "mysql", "postgres"
  - Default "mysql"

* gitlab['database']['adapter']
  - The Rails adapter to use with the database type
  - Options: "mysql2", "postgresql"
  - Default (varies based on `type`)

* gitlab['database']['encoding']
  - The database encoding
  - Default (varies based on `type`)

* gitlab['database']['host']
  - The host (fqdn) where the database exists
  - Default `localhost`

* gitlab['database']['pool']
  - The maximum number of connections to allow
  - Default 5

* gitlab['database']['database']
  - The name of the database
  - Default `gitlab`

* gitlab['database']['username']
  - The username for the database
  - Default `gitlab`

### LDAP Authentication Attributes

* `gitlab'['ldap']['enabled']`
  - Use LDAP for authentication
  - Default: false

* `gitlab['ldap']['host']`
  - Hostname of your LDAP server
  - Default: "_your_ldap_server"

* `gitlab['ldap']['base']`
  - Base DN for users (e.g. dc=users,dc=example,dc=com)
  - Default: "_the_base_where_you_search_for_users"

* `gitlab['ldap']['port']`
  - LDAP server port
  - Default: 636

* `gitlab['ldap']['uid']`
  - User ID used when searching for users (e.g. uid, cn, or sAMAccountName)
  - Default: "sAMAccountName"

* `gitlab['ldap']['method']`
  - Connection method used with LDAP server
  - Options: "ssl", "plain"
  - Default: "ssl"

* `gitlab['ldap']['bind_dn']`
  - Some servers require a username in order to bind
  - Default: "_the_full_dn_of_the_user_you_will_bind_with"

* `gitlab['ldap']['password']`
  - Some servers require a password in order to bind
  - Default: "_the_password_of_the_bind_user"

* `gitlab['ldap']['allow_username_or_email_login']`
  - If you want to allow users to login using both username and email address even though username (uid) will actually be used
  - Default: true

Usage
=====

Optionally override application paths using gitlab['git\_home'] and gitlab['home'].

Add recipe gitlab::default to run\_list.  Go grab a lunch, or two, if Ruby has to build.

The default admin credentials for the gitlab application are as follows:

    User: admin@local.host
    Password: 5iveL!fe

Of course you should change these first thing, once deployed.

## Role example for Gitlab with https, and MySQL

```
name "gitlab_https"
description "Configures and installs gitlab w/ https, and mysql server"
override_attributes "gitlab" => {
  "https" => true,
  "certificate_databag_id" => "wildcard"
}
run_list "recipe[mysql::server]", "recipe[gitlab]
```

License and Author
==================

Author: Gerald L. Hevener Jr., M.S.
Copyright: 2012

Author: Eric G. Wolfe
Copyright: 2012

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
