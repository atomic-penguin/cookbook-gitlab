#
# Cookbook Name:: gitlab
# Recipe:: runner
#
# Copyright 2016, Yakara Ltd
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

packagecloud_repo 'runner/gitlab-ci-multi-runner' do
  base_url 'https://packages.gitlab.com'
end

package 'gitlab-ci-multi-runner'
