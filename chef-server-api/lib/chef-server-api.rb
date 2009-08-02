if defined?(Merb::Plugins)
  $:.unshift File.dirname(__FILE__)
  $:.unshift File.join(File.dirname(__FILE__), "..", "..", "chef-solr", "lib")
  $:.unshift File.join(File.dirname(__FILE__), "..", "..", "chef", "lib")

  dependency 'merb-slices', :immediate => true
  dependency 'chef', :immediate=>true unless defined?(Chef)
  dependency 'nanite', :immediate=>true 

  require 'chef/role'
  require 'chef/data_bag'
  require 'chef/data_bag_item'
  require 'chef/nanite'

  require 'mixlib/auth'

  require 'chef/data_bag'
  require 'chef/data_bag_item'
  require 'ohai'
  require 'chef/nanite'

  require 'syntax/convertors/html'
  
  Merb::Plugins.add_rakefiles "chef-server-api/merbtasks", "chef-server-api/slicetasks", "chef-server-api/spectasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)

  Merb.disable :json

  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can switch to
  # the main application layout or no layout at all if needed.
  #
  # Configuration options:
  # :layout - the layout to use; defaults to :chefserverslice
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:chef_server_api][:layout] ||= :chef_server_api
  
  # All Slice code is expected to be namespaced inside a module
  module ChefServerApi
    # Slice metadata
    self.description = "ChefServerApi.. serving up some piping hot infrastructure!"
    self.version = Chef::VERSION
    self.author = "Opscode"

    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
      Chef::Log.info("Compiling routes... (totally normal to see 'Cannot find resource model')")
    end

    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end

    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
      Nanite::Log.logger = Mixlib::Auth::Log.logger = Ohai::Log.logger = Chef::Log.logger 
      Merb.logger.set_log(STDOUT, Chef::Config[:log_level])
      Thread.new do
        until EM.reactor_running?
          sleep 1
        end
        Chef::Nanite.in_event { Chef::Log.info("Nanite is ready") }

        # create the couch design docs for nodes, roles, and databags
        Chef::CouchDB.new.create_id_map
        Chef::Node.create_design_document
        Chef::Role.create_design_document
        Chef::DataBag.create_design_document

        Chef::Log.info('Loading roles')
        Chef::Role.sync_from_disk_to_couchdb
      end
    end

    # Deactivation hook - triggered by Merb::Slices.deactivate(Chefserver)
    def self.deactivate
    end

    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :chefserverslice_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
      # Nodes
      scope.match('/nodes/:id/cookbooks', :method => 'get').to(:controller => "nodes", :action => "cookbooks")
      scope.resources :nodes

      # Roles
      scope.resources :roles

      # Status
      scope.match("/status").to(:controller => "status", :action => "index").name(:status)


      # Search
      scope.resources :search

      # Cookbooks        
      scope.match('/nodes/:id/cookbooks', :method => 'get').to(:controller => "nodes", :action => "cookbooks")

      scope.match("/cookbooks", :method => 'get').to(:controller => "cookbooks", :action => "index")
      scope.match("/cookbooks", :method => 'post').to(:controller => "cookbooks", :action => "create")
      scope.match("/cookbooks/:cookbook_id", :method => 'get', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "show").name(:cookbook)
      scope.match("/cookbooks/:cookbook_id", :method => 'delete', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "destroy")
      scope.match("/cookbooks/:cookbook_id/_content", :method => 'get', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "get_tarball")
      scope.match("/cookbooks/:cookbook_id/_content", :method => 'put', :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "update")
      scope.match("/cookbooks/:cookbook_id/:segment", :cookbook_id => /[\w\.]+/).to(:controller => "cookbooks", :action => "show_segment").name(:cookbook_segment)

      # Data
      scope.match("/data/:data_bag_id/:id", :method => 'get').to(:controller => "data_item", :action => "show").name("data_bag_item")
      scope.match("/data/:data_bag_id/:id", :method => 'put').to(:controller => "data_item", :action => "create").name("create_data_bag_item")
      scope.match("/data/:data_bag_id/:id", :method => 'delete').to(:controller => "data_item", :action => "destroy").name("destroy_data_bag_item")
      scope.resources :data

      scope.match('/').to(:controller => 'main', :action =>'index').name(:top)
    end
  end
    
  # TODO: make this read from an environment-specific file
  Merb::Config.use do |c|
    c[:couchdb_uri] = Chef::Config[:couchdb_url] 
    c[:couchdb_database] = Chef::Config[:couchdb_database] 
  end
  
  COUCHDB = CouchRest.new(Merb::Config[:couchdb_uri])
  COUCHDB.database!(Merb::Config[:couchdb_database])
  COUCHDB.default_database = Merb::Config[:couchdb_database]
  
  Mixlib::Auth::AuthJoin.use_database(COUCHDB.default_database)
  Mixlib::Auth::PRIVKEY = Chef::Config[:validation_key]
  
  # Setup the slice layout for ChefServerApi
  #
  # Use ChefServerApi.push_path and ChefServerApi.push_app_path
  # to set paths to chefserver-level and app-level paths. Example:
  #
  # ChefServerApi.push_path(:application, ChefServerApi.root)
  # ChefServerApi.push_app_path(:application, Merb.root / 'slices' / 'chefserverslice')
  # ...
  #
  # Any component path that hasn't been set will default to ChefServerApi.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  ChefServerApi.setup_default_structure!
end
