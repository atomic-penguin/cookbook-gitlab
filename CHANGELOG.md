## v0.3.5

Fix issues with stable snapshot v3.x

* Add LDAP auth options

Issues #16 and #17

Issue 16: The section that runs the bundle command does not work correctly on Debian and Ubuntu distros. I modified the cookbook in order to install the Ruby 1.9.2 packages and add new flavours for the Ruby commands with the  update-alternatives command.

Issue 17: The public key is saved in the node only if the private key is created. 

## v0.3.4

Fix issues with stable snapshot v3.x
    
* Avoid installing pg, gem which adds extra dependencies
* Add change to default gitolite.rc per upgrade instructions

## v0.3.3

Issues #9 and #10

Issue 9: this version MAY fix issues with key generation when
cookbook is invocated via chef-solo.  There may exist other
chef-solo blockers within the cookbook.  Specifically, `File.exists?`
guards were added to SSH public key generation code blocks.

Issue 10: this version fixes one minor dependency bug with EPEL
dependencies via metadata and inclusion.

## v0.3.2

* Default gitlab branch to stable

## v0.3.1

* ISSUE 7: public key template fails to render
* ISSUE 8: unicorn_rails script fails on ruby package platforms 

## v0.3.0

* Missing bracket
* Change single-quote variable to symbol notation
* install python and symlink redis-cli so hooks work
* HTTPS options for nginx
* Ubuntu/Debian platform compatibility fixes
* [FC035](http://acrmp.github.com/foodcritic/#FC035): Template uses node attribute directly

## v0.2.1

  Thanks to Fletcher Nichol for the feedback and fixes :)

  * Add `gitlab_branch` attribute.
  * Fix directory block syntax (do).

## v0.2.0

  * Epic public release <crowd cheers>
  * Moar testing
  * Clean up init script
  * Fix unicorn config
  * Fix gitlab home permissions for nginx

## v0.1.0

  ### Epic refactor

  * Write long README
  * variable renaming to simplify readability
  * refactor dependencies and package lists
  * generate ssh keys in Ruby, import to gitolite
  * Integrate gitolite recipe into cookbook 
  * Fix broken ssh problems
  * fixup git home permissions
  * use system ruby instead of chef-full bundler
  * Re-work dependencies; Prefer ruby_build rubies over Redhat shipped

## v0.0.1 - v0.0.40

  ### Prototyping

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
