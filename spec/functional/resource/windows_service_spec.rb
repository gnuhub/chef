#
# Author:: Chris Doherty (cdoherty@chef.io>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'spec_helper'

describe Chef::Resource::WindowsService, :windows_only, :system_windows_service_gem_only do

  include_context "using Win32::Service"

  let(:username) { "service_spec_user"}
  let(:qualified_username) { ".\\#{username}"}
  let(:password) { "changeme"}

  let(:user_resource) {
    r = Chef::Resource::User.new(username, run_context)
    r.username(username)
    r.password(password)
    r.comment("temp spec user")
    r
  }

  let(:global_service_file_path) {
    "#{ENV['SystemDrive']}\\windows\\temp\\#{File.basename(test_service[:service_file_path])}"
  }

  let(:service_params) {
    test_service.merge( {
      run_as: qualified_username,
      run_as_password: password,
      service_display_name: "windows_service test service",
      service_description: "Test service for running the windows_service functional spec.",
      service_file_path: global_service_file_path,
      } )
  }

  let(:manager) {
    Chef::Application::WindowsServiceManager.new(service_params)
  }

  let(:service_resource) {
    r = Chef::Resource::WindowsService.new(service_params[:service_name], run_context)
    [:run_as, :run_as_password].each { |prop| r.send(prop, service_params[prop]) }
    r
  }

  before {
    user_resource.run_action(:create)
    FileUtils::copy_file(test_service[:service_file_path], global_service_file_path)

    # if you don't make the file executable by the service user, you'll get
    # the not-very-helpful "service did not respond fast enough" error.
    file = Chef::Resource::File.new(global_service_file_path, run_context)
    # this may break in a post-Windows 8.1 release, and have to be replaced with the rights stuff in the file resource.
    file.mode("0777")
    file.run_action(:create)

    manager.run(%w{--action install})
  }

  after {
    user_resource.run_action(:remove)
    manager.run(%w{--action uninstall})
    File.delete(global_service_file_path)
  }

  describe "logon as a service" do
    it "runs a service as another user" do
      service_resource.run_action(:start)
    end
  end
end
