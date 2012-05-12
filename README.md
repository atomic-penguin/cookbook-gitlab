Description
===========

This cookbook will deploy gitlab; a free project and repository management
application.

Code hosted on github [here](https://github.com/gitlabhq/gitlabhq/tree/stable).

This cookbook was developed on RHEL/CentOS 6.  Other platforms may need re-worked,
please open an issue or send a pull request to either, atomic-penguin or jackl0phty, on github.

Requirements
============

* Hard disk space
  - About 200 Mb, plus enough space for repositories on /var

* Ruby 1.9.1 packages
  - Packages used for Debian / Ubuntu only

* Nginx package
  - All platforms need an nginx package to configure Nginx and Unicorn.

Cookbooks + Acknowledgements
----------------------------

The dependencies in this cookbook add up to over 1,500 lines of code.
This would not have been possible without the great community work of so many others.
Much kudos to everyone who added indirectly to the epicness of this cookbook.

* [ruby\_build](http://fnichol.github.com/chef-ruby_build/)
  - Thanks to Fletcher Nichol for his awesome ruby\_build cookbook.
    This ruby\_build LWRP is used to build Ruby 1.9.2 for gitlab,
    since Redhat shipped rubies are not compatible with the application.

* gitolite
  - Big thanks to Ruan David's [gitolite](http://ckbk.it/gitolite) as
    it certainly helped with the development of this cookbook.
    Unfortunately we had to implement our cookbook in such a way that
    directly conflicts with the original cookbook.

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
  - [sqlite](http://ckbk.it/sqlite)
  - [build-essential](http://ckbk.it/build-essential)
  - [python::pip](http://ckbk.it/python)
  - [sudo](http://ckbk.it/sudo)
  - [openssh](http://ckbk.it/openssh)
  - [perl](http://ckbk.it/perl)
  - [xml](http://ckbk.it/xml)
  - [zlib](http://ckbk.it/zlib)


Notes about conflicts
---------------------

* [gitolite](http://ckbk.it/gitolite) cookbook
  - The gitolite recipe within our cookbook was based on David Ruan's cookbook.
    We couldn't integrate gitolite and gitlab without significant rework on David's
    original cookbook.  Our gitolite recipe will only configure gitolite for use with gitlab.
    Our gitlab::gitolite recipe will not set up a standalone gitolite installation as David's
    cookbook does.

* [nginx](http://ckbk.it/nginx) cookbook
  - Our default recipe templates out the /etc/nginx/conf.d/default.conf.  This will directly
    conflict with another cookbook, such as nginx, trying to manage this file.

Attributes
==========

* gitlab['gitolite\_url']
  - Github gitolite address
  - Default git://github.com/sitaramc/gitolite.git

* gitlab['git\_user'] & gitlab['git\_group']
  - Git service account for gitolite
  - Default git

* gitlab['git\_home']
  - Top-level home for gitolite and repositories
  - Default /var/git

* gitlab['gitolite\_home']
  - Application home for gitolite
  - Default /var/git/gitolite

* gitlab['gitolite\_umask']
  - Umask setting for gitolite.rc
  - Defaults to 0007

* gitlab['user'] & gitlab['group']
  - Gitlab service user and group for Unicorn Rails app
  - Default gitlab

* gitlab['home']
  - Gitlab top-level home for service account
  - default /var/gitlab

* gitlab['app\_home']
  - Gitlab application home
  - Default /var/gitlab/gitlab

* gitlab['gitlab\_url']
  - Github gitlab address
  - Default git://github.com/gitlabhq/gitlabhq.git

* gitlab['gitlab\_branch']
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
