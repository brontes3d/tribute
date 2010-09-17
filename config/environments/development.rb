# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# enable email delivery for local debug in mailtrap
# config.action_mailer.raise_delivery_errors = true
# config.action_mailer.perform_deliveries = true
# config.action_mailer.delivery_method = :smtp
# config.action_mailer.smtp_settings = {
#   :domain => "mmm.com",
#   :address => "localhost",
#   :port => 2525,
# }

SKIP_CAS_LOGIN = true

CASCLIENT_FRAMEWORKS_RAILS_FILTER_CONF = {
  :cas_base_url => "http://localhost:2999/sso"
}

BRONTES_LOG_DIRECTORY = "log/passenger"

# config for memcache connections from plugins
# MEMCACHE_CONFIG = ['localhost:11211', {:namespace => 'my_namespace'}]
# MEMCACHE_CONFIG = [ ["one.example.com:11211", "two.example.com:11211"], {:namespace => 'my_namespace'} ]
MEMCACHE_SERVERS = ['localhost:11211']
MEMCACHE_CONFIG  = [MEMCACHE_SERVERS, {:namespace => "cm4:#{Rails.env}"}]

config.action_controller.session_store = :mem_cache_store

config.action_controller.session = {
  :session_key     => '_cm4_tribute_session',
  :memcache_server => MEMCACHE_SERVERS,
  :namespace       => "rack:session:core:#{Rails.env}",
  :expire_after    => 4.hours
}
