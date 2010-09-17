# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Use SQL instead of Active Record's schema dumper when creating the test database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
# config.active_record.schema_format = :sql

CASCLIENT_FRAMEWORKS_RAILS_FILTER_CONF = {:cas_base_url => "http://localhost:2999/sso"}

# intentially configured to be invalid arguments to memcache
# we should never be hitting actual memcache in our tests
MEMCACHE_SERVERS = ['localhost:0']
MEMCACHE_CONFIG  = [MEMCACHE_SERVERS, {:namespace => "cm4:#{Rails.env}"}]

config.action_controller.session_store = :cookie_store

config.action_controller.session = {
  :key          => '_cm4_tribute_session',
  :secret       => 'x',
  :expire_after => 4.hours
}

def I18n::just_raise_that_exception(*args)
  raise args.first
end

I18n.exception_handler = :just_raise_that_exception
