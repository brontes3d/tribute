# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.9' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.autoload_paths.unshift "#{RAILS_ROOT}/business/controllers"
  # config.autoload_paths.unshift "#{RAILS_ROOT}/business/helpers"
  # config.autoload_paths.unshift "#{RAILS_ROOT}/business/amqp_listeners"
  config.autoload_paths.unshift "#{RAILS_ROOT}/app/amqp_listeners"
  # config.view_path = ["#{RAILS_ROOT}/app/views", "#{RAILS_ROOT}/business/views"]
  
  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  
  config.gem "fastercsv", :version => '1.5.3'
  config.gem "daemons", :version => '1.1.0'
  config.gem "validates_as_email_address", :version => "0.2.4"
  
  config.gem 'brontes3d-amqp', 
              :lib      => "mq",
              :version  => "0.6.7.1"

  config.gem 'bunny', 
              :version    => "0.6.0"

  config.gem 'eventmachine', 
              :version    => "0.12.10"
  
  config.gem "brontes3d-production_log_analyzer", :lib => "rack_logging_per_proc", :version => "2009072200"
  
  #CCRB prod data migration tests run as RAILS_ENV=test
  #so we can't key off THAT to decide whether or not to include these test gems
  #if we did, we would end up requiring test unit which would attempt to 
  #run all tests after the migration task
  #but as it stands here with if defined?(Test::Unit)
  #we will never be able to get the output of rake gems to tell us that these gems are needed
  #and test_helper calls 'require' for all of these gems anyway
  #so this decleration is basically just as good as having them in this file commented out
  #these config.gems call are for documenting what gems our tests require
  if defined?(Test::Unit)
    config.gem "shoulda", :version => '2.11.1'
    config.gem "factory_girl", :version => "1.3.2"
    config.gem "webrat"
    config.gem "mocha"
    config.gem "nokogiri"
  end
  
  config.gem "SystemTimer", :version => "1.2", :lib => 'system_timer' # this is need because its a dependency for memcache-client
  config.gem "memcache-client", :lib => "memcache", :version => "1.8.5"
  require 'memcache' # <-- cause rails is being stupid about thinking this is a "Framework gem", 
                           #and therefore already loaded, so it won't load it for us
  
  config.gem "savon", :version => "0.7.9"
  #rails dependencies:
  config.gem "rack", :version => "1.1.0"
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
  
  # config.routes_configuration_file = File.join(RAILS_ROOT, "business", "routes.rb")  
  
end

# AmqpListener.listener_load_paths << "#{RAILS_ROOT}/business/amqp_listeners/*.rb"

