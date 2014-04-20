#!/usr/bin/env rake
# encoding: utf-8

#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
# License:: Apache License, Version 2.0
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

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

{
  :test => '**',
  :unit => 'unit',
  :integration => 'integration',
}.each do |test, dir|
  Rake::TestTask.new(test) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = "test/#{dir}/test_*.rb"
    test.verbose = true
  end
end

task :default => :test
