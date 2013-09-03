## Description

This cookbook will deploy gitlab; a free project and repository management
application.

Code hosted on github [here](https://github.com/gitlabhq/gitlabhq/tree/stable).

Tested successfully with Gitlab 6-0-stable on Ubuntu 13.04 with Chef 11

## Requirements
============

* Hard disk space
  - About 200 Mb, plus enough space for repositories on /var

* Ruby 1.9.1 packages
  - Packages used for Debian / Ubuntu only

## Cookbooks + Acknowledgements
=======

The dependencies in this cookbook add up to over 1,500 lines of code.
This would not have been possible without the great community work of so many others.
Much kudos to everyone who added indirectly to the epicness of this cookbook.

* [ruby\_build](http://fnichol.github.com/chef-ruby_build/)
  - Thanks to Fletcher Nichol for his awesome ruby\_build cookbook.
    This ruby\_build LWRP is used to build Ruby 1.9.2 for gitlab,
    since Redhat shipped rubies are not compatible with the application.

* [chef\_gem](http://ckbk.it/chef_gem)
  - Thanks to Chris Roberts for this little gem helper.  This cookbook
    provides a compatible gem resource for Omnibus on Chef versions less
    than 0.10.8

* [redisio](http://ckbk.it/redisio)
  - Thanks to Brian Bianco for this Redis cookbook, because I don't know
    anything about Redis.  Thanks to this cookbook I still don't know
    anything about Redis, and that is the best kind of cookbook.  One
    that just works out of the box.

* Opscode, Inc cookbooks
  - [git](http://ckbk.it/git)
  - [build-essential](http://ckbk.it/build-essential)
  - [python::pip](http://ckbk.it/python)
  - [sudo](http://ckbk.it/sudo)
  - [nginx](http://ckbk.it/nginx)
  - [openssh](http://ckbk.it/openssh)
  - [perl](http://ckbk.it/perl)
  - [xml](http://ckbk.it/xml)
  - [zlib](http://ckbk.it/zlib)


Attributes
==========

* gitlab['user'] & gitlab['group']
  - Gitlab service user and group for Unicorn Rails app
  - Default gitlab

* gitlab['home']
  - Gitlab top-level home for service account
  - default /var/gitlab

* gitlab['app\_home']
  - Gitlab application home
  - Default /var/gitlab/gitlab

* gitlab['email\_from']
  - Gitlab email from
  - Default gitlab@example.com 

* gitlab['support\_email']
  - Gitlab support email
  - Default support@example.com 

* gitlab['git\_url']
  - Github gitlab address
  - Default git://github.com/gitlabhq/gitlabhq.git

* gitlab['git\_branch']
  - Gitlab git branch
  - Default master

* gitlab['packages']
  - Platform specific OS packages

* gitlab['trust\_local\_sshkeys']
  - ssh\_config key for gitlab to trust localhost keys automatically
  - Defaults to yes

* gitlab['install\_ruby']
  - Attribute to determine whether vendor packages are installed,
    or Rubies are built
  - Redhat family defaults 1.9.2; Debian family defaults to package.

* gitlab['https']
  - Whether https should be used
  - Default false

* gitlab['ssl\_certificate'] & gitlab['ssl\_certificate\_key']
  - Location of certificate file and key if https is true.
    A self-signed certificate is generated if certificate is not present.
  - Default /etc/nginx/#{node['fqdn']}.crt and /etc/nginx/#{node['fqdn']}.key

* gitlab['ssl\_req']
  - Request subject used to generate a self-signed SSL certificate

* gitlab['backup\_path']
  - Path in file system where backups are stored.
  - Defaults to gitlab['app\_home'] + backups/

* gitlab['backup\_keep\_time']
  - In seconds. Older backups will automatically be deleted when new backup is created. Set to 0 to keep backups forever.
  - Defaults to 604800

* gitlab['listen\_ip']
  - IP address that nginx will listen on
  - Default * (listen on all IPs)

* gitlab['listen\_port']
  - Port that nginx will listen on
  - Defaults to 80 if gitlab['https'] is set to false, 443 if it's set to true

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

Usage
=====

Optionally override application paths using gitlab['git\_home'] and gitlab['home'].

Add recipe gitlab::default to run\_list.  Go grab a lunch, or two, if Ruby has to build.

The default admin credentials for the gitlab application are as follows:

    User: admin@local.host
    Password: 5iveL!fe

Of course you should change these first thing, once deployed.

License and Author
==================

Author: Gerald L. Hevener Jr., M.S.
Copyright: 2012

Author: Eric G. Wolfe
Copyright: 2012

Gitlolite Author: David Ruan
Copyright: RailsAnt, Inc., 2010

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
