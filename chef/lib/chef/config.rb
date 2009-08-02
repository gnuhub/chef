#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/log'
require 'mixlib/config'

class Chef
  class Config

    extend Mixlib::Config

    # Manages the chef secret session key
    # === Returns
    # <newkey>:: A new or retrieved session key
    #
    def self.manage_secret_key
      newkey = nil
      if Chef::FileCache.has_key?("chef_server_cookie_id")
        newkey = Chef::FileCache.load("chef_server_cookie_id")
      else
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        newkey = ""
        40.times { |i| newkey << chars[rand(chars.size-1)] }
        Chef::FileCache.store("chef_server_cookie_id", newkey)
      end
      newkey
    end


    # Override the config dispatch to set the value of multiple server options simultaneously
    # 
    # === Parameters
    # url<String>:: String to be set for all of the chef-server-api URL's
    #
    def self.chef_server_url=(url)
      configure do |c|
        [ :registration_url,
          :openid_url,
          :template_url,
          :remotefile_url,
          :search_url,
          :chef_server_url,
          :role_url ].each do |u| 
            c[u] = url
        end
      end
    end

    # Override the config dispatch to set the value of log_location configuration option
    #
    # === Parameters
    # location<IO||String>:: Logging location as either an IO stream or string representing log file path
    #
    def self.log_location=(location)
      configure { |c| c[:log_location] = (location.respond_to?(:sync=) ? location : File.new(location, "w+")) }
    end

    # Override the config dispatch to set the value of authorized_openid_providers when openid_providers (deprecated) is used
    #
    # === Parameters
    # providers<Array>:: An array of openid providers that are authorized to login to the chef server
    #
    def self.openid_providers=(providers)
      configure { |c| c[:authorized_openid_provders] = providers }
    end

    authorized_openid_identifiers nil
    authorized_openid_providers nil
    chef_server_url "http://localhost:4000"
    cookbook_path [ "/var/chef/site-cookbooks", "/var/chef/cookbooks" ]
    couchdb_database "chef"
    couchdb_url "http://localhost:5984"
    couchdb_version nil
    daemonize nil
    delay 0
    executable_path ENV['PATH'] ? ENV['PATH'].split(File::PATH_SEPARATOR) : []
    file_cache_path "/var/chef/cache"
    file_store_path "/var/chef/store"
    group nil
    http_retry_count 5
    http_retry_delay 5
    interval nil
    json_attribs nil
    log_level :info
    log_location STDOUT
    node_name nil
    node_path "/var/chef/node"
    openid_cstore_couchdb false
    openid_cstore_path "/var/chef/openid/cstore"
    openid_providers nil
    openid_store_couchdb false
    openid_store_path "/var/chef/openid/db"
    openid_url "http://localhost:4001"
    pid_file nil
    registration_url "http://localhost:4000"
    certificate_url "http://localhost:4000"
    client_url "http://localhost:4042"
    remotefile_url "http://localhost:4000"
    rest_timeout 60
    run_command_stderr_timeout 120
    run_command_stdout_timeout 120
    search_index_path "/var/chef/search_index"
    search_url "http://localhost:4000"
    solo  false
    splay nil
    ssl_client_cert ""
    ssl_client_key ""
    ssl_verify_mode :verify_none
    template_url "http://localhost:4000"
    user nil
    validation_token nil
    role_path "/var/chef/roles"
    role_url "http://localhost:4000"
    recipe_url nil
    solr_url "http://localhost:8983"
    solr_jetty_path "/var/chef/solr-jetty"
    solr_data_path "/var/chef/solr/data"
    solr_home_path "/var/chef/solr"
    solr_heap_size "256M"
    solr_java_opts nil
    nanite_host '0.0.0.0'
    nanite_port '5672'
    nanite_user 'nanite'
    nanite_pass 'testing'
    nanite_vhost '/nanite'
    nanite_identity nil

    client_key "/etc/chef/client.pem"
    validation_key "/etc/chef/validation.pem"
    validation_client_name "chef-validator"

  end
end
