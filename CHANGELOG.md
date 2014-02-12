Gitlab Cookbook Changelog
=========================

v6.4.3
------

* Include new user privileges attributes.
* Some README.md points on LDAP auth when anonymous binding is enabled on server.
* Fix Path issue when executing bundle. It was using chef-client embedded ruby instead gitlab one.
  - Just adding the path to the giltab bin directory at the beginning of the command.

v6.4.2
------

* Add a profile script shim, so init script can correct Ruby.

v6.4.1
------

* Issue #60 - thanks to @nickryand
  - Modified the bundle install command to drop a file on successful
    completion 
  - Added the absolute path to the bundler binary installed into the
    system ruby path.
  - Added a more accurate pattern matcher to gitlab service resource
    so Chef can find unicorn_rails processes instead of finding processes that
    have the 'gitlab' string in them.
  - Changed the background call to script/web and script/background_jobs
    in the startup script.  These are now foreground calls forcing the start
    script to block until they return (after the processes are up).  This
    prevents the Chef run from completing before the unicorn_rails processes
    are up.

* Other fixes/tweaks
  - Remove yum dependency hell.
  - Change init/database.yml order due to service subscription.
  - Add a :80 redirect to :443, avoids default site showing on :80
    when `gitlab['https']` set.

* Update test files
  - Pin omnibus version at 11.8.2, redisio remote file resource failure.
  - Remove explicit nil on databag_certificate_id, fails on default suite 
  - Remove support Gemfile, and update travis.yml
  - Add bats tests for default/https suites

v6.4.0
------

  * Bump gitlab-shell to v1.8.0
  * Bump gitlab to 6.4.0
  * Remove stale nginx config file
  * Default recipe changes
    - Update gitlab-shell config to point at /usr/local/bin/redis-cli
    - Fix permissions on .ssh/authorized_keys
    - Add rack_attack file
    - Add precompile assets execute
    - Add logrotate dependency and configuration 

v6.1.21
-------

  * Add node['database']['userhost'] attribute, fixes #57
  * Fix gitlab['listen_port']/gitlab['https'] condition, fixes #58
  * Add node['gitlab']['self_signed_cert'] and documentation, fixes #58
  * Revert yum-epel changes, COOK-4164 blocking, will re-open
    - Fix dependency hell w/ nginx cookbook
  * Add rubocop linting
  * Add chefspec mysql/postgres http/https branching specs
  * Remove unneeded python dependency 

v6.1.10
-------

Bugs squashed:

  * Re-order database components to fix Ubuntu Test-Kitchen run. #44
  * Update port forwarding configuration in kitchen.yml. #46
  * Update Satellite paths to fix Gitlab forking. #50
  * ruby-build installs to node['gitlab']['home'], avoiding PATH hacks
    for Rake.  Use node['gitlab']['install_ruby_path'] to override. #16
  * ruby-build failing on 1.9.3-p448, bump version to 1.9.3-p484.
  * Pinned yum dependency on < 3.0.0

Features added:

  * Add knob for disabling Gravatar. #51
  * Add LDAP Authentication support. #49

Removed:

  * sudo cookbook dependency removed. #52

v6.1.0
------

Clean up some of the code to target [6-1-stable branch](https://github.com/gitlabhq/gitlabhq/blob/6-1-stable/doc/install/installation.md)

* Move gitlab.home to /srv/git - [FHS 2.3](http://www.pathname.com/fhs/pub/fhs-2.3.html)
* Use ruby_build to compile 1.9.3 by default per gitlabhq documentation.
* Clean up both cookbook and package dependencies.
* Remove ruby-shadow, included in Omnibus, not needed anyway as no
  password is set.
* Use gitconfig template, instead of execute.
* Add test-kitchen skeleton, and certificate data_bag integration.
  - Add gitlab.certificate_databag_id to deploy certificate from encrypted databag.
* Minor sudo fix in gitlab init script.
* Use nginx_site definition to disable default nginx site.
* Add nginx_server_names array for hostname match precedence over potential default sites matching `_`.

v0.5.0
------

* Database back-end changes via @sethvargo
  - Adds a mysql and postgresql database creation 
  - **Breaking change**: developed against githlabhq/master (sqlite no longer supported)

* Gitolite deploy changes via @dscheu
  - Deploy gitlabhq/gitolite, not sitaramc/gitolite

* Add configurable backup paths to Gitlab configuration via @dscheu

v0.3.4
------

Fix issues with stable snapshot v3.x
    
* Avoid installing pg, gem which adds extra dependencies
* Add change to default gitolite.rc per upgrade instructions

v0.3.3
------

Issues #9 and #10

Issue 9: this version MAY fix issues with key generation when
cookbook is invocated via chef-solo.  There may exist other
chef-solo blockers within the cookbook.  Specifically, `File.exists?`
guards were added to SSH public key generation code blocks.

Issue 10: this version fixes one minor dependency bug with EPEL
dependencies via metadata and inclusion.

v0.3.2
------

* Default gitlab branch to stable

v0.3.1
------

* ISSUE 7: public key template fails to render
* ISSUE 8: unicorn_rails script fails on ruby package platforms 

v0.3.0
------

* Missing bracket
* Change single-quote variable to symbol notation
* install python and symlink redis-cli so hooks work
* HTTPS options for nginx
* Ubuntu/Debian platform compatibility fixes
* [FC035](http://acrmp.github.com/foodcritic/#FC035): Template uses node attribute directly

v0.2.1
------

  Thanks to Fletcher Nichol for the feedback and fixes :)

  * Add `gitlab_branch` attribute.
  * Fix directory block syntax (do).

v0.2.0
------

  * Epic public release <crowd cheers>
  * Moar testing
  * Clean up init script
  * Fix unicorn config
  * Fix gitlab home permissions for nginx

v0.1.0
------

  #Epic refactor

  * Write long README
  * variable renaming to simplify readability
  * refactor dependencies and package lists
  * generate ssh keys in Ruby, import to gitolite
  * Integrate gitolite recipe into cookbook 
  * Fix broken ssh problems
  * fixup git home permissions
  * use system ruby instead of chef-full bundler
  * Re-work dependencies; Prefer ruby_build rubies over Redhat shipped

v0.0.1 - v0.0.40
----------------

  #Prototyping

  Added cookbook dependencies for gitlab/gitolite
  Prototype attributes for gitlab cookbook
  Fixed gitolite support for gitlab in default.rb
  Fixed permissions & gl-setup in gitlab default.rb
  Edit default.rb in gitlab & gitolite cookbooks
  Edit gitolite cmd to add .pub key
  Fix code blocks in wrong order gitolite/gitlab ckbks
  Refactor gitolite/gitlab ckbks again. Works now.
  Add cookbooks redisio & sqlite. Install pkgs for gitlab
  Install Gems. Rename config files 4 gitlab cookbook
  Config Sqlite DB for gitlab
  Add ability to start gitlab & resque
