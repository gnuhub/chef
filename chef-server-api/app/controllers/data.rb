#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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
#

require 'chef/data_bag'

class ChefServerApi::Data < ChefServerApi::Application
  
  provides :json
  
  before :authenticate_every
  
  def index
    @bag_list = Chef::DataBag.list(false)
    display(@bag_list.collect { |b| absolute_slice_url(:organization_datum, :id => b, :organization_id => @organization_id) })
  end

  def show
    begin
      @data_bag = Chef::DataBag.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load data bag #{params[:id]}"
    end
    display(@data_bag.list.collect { |i| absolute_slice_url(:organization_data_bag_item, :data_bag_id => @data_bag.name, :id => i) })
  end

  def create
    @data_bag = nil
    if params.has_key?("inflated_object")
      @data_bag = params["inflated_object"]
    else
      @data_bag = Chef::DataBag.new
      @data_bag.name(params["name"])
    end
    exists = true 
    begin
      Chef::DataBag.load(@data_bag.name)
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false
    end
    raise Forbidden, "Data bag already exists" if exists
    self.status = 201
    @data_bag.save
    display({ :uri => absolute_slice_url(:organization_datum, :id => @data_bag.name, :organization_id => @organization_id) })
  end

  def destroy
    begin
      @data_bag = Chef::DataBag.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e 
      raise NotFound, "Cannot load data bag #{params[:id]}"
    end
    @data_bag.destroy
    @data_bag.couchdb_rev = nil
    display @data_bag
  end
  
end
