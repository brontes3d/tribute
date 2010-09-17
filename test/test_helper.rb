require 'rubygems'
require 'test/unit/notification'
require 'test/unit'

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require File.expand_path(File.join(File.dirname(__FILE__) , "helpers/email_tests_helper"))

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def setup(opts_given = {})
    opts = {:stub_amqp => true, :use_transactional => true, :mock_soap => true}.merge(opts_given)
    if opts[:stub_amqp]
      @messages_sent = []
      AmqpListener.stubs(:send_to_exchange).returns(true).with do |arg1, arg2|
        # puts "new message to #{arg1}"
        @messages_sent << [arg1, arg2]
        true
      end
      AmqpListener.stubs(:send).returns(true).with do |arg1, arg2|
        # puts "new message to #{arg1}"
        @messages_sent << [arg1, arg2]
        true
      end
    end
    if opts[:use_transactional]
      CommitCallback.adapt_for_transactional_test!(ActiveRecord::Base.connection)
    else
      ActiveRecord::Base.connection.rollback_db_transaction
      ActiveRecord::Base.connection.decrement_open_transactions      
    end
    
    Savon::Client.any_instance.stubs(:publish_case_manager_xml).yields(mock{stubs(:body=).returns(true)}).returns("a good response, since eai doesn't send anything else")
    User.current_user= User.current_user || User.new(:username => "tribute_test_user", :user_number => 1337, :remote_roles => {})
  end
  
  def run_all_messages
    while(!@messages_sent.empty?)
      run_one_message
    end
  end
  
  def run_one_message
    @messages_ran ||= {}
    # puts @messages_sent.size
    (q, m) = @messages_sent.shift
    # puts "running message to #{q}"
    @messages_ran[q] ||= []
    @messages_ran[q] << m
    run_mesage(q, m)
  end
  
  def run_mesage(q, m)
    AmqpListener.listeners.each do |l|
      if l.queue_name.to_s == q.to_s
        listener = l.new
        # puts "#{listener} is handling message: #{m}"
        #TODO: listener base should define a convenience method for on_message
        begin 
          if listener.respond_to?(:transform_message)
            listener.on_message(listener.transform_message(m))
          else
            listener.on_message(m)
          end
        rescue Exception => exception
          AmqpListener.get_exception_handler.call(listener, m, exception)
          raise
        end
      end
    end    
  end
  
end

User.class_eval do
  class << self
    attr_accessor :current_user
  end
end

require "webrat"

Webrat.configure do |config|
  config.mode = :rails
end

if File.exists?("#{RAILS_ROOT}/business/test/test_mocks.rb")
  require "#{RAILS_ROOT}/business/test/test_mocks"
end

AmqpListener.load_listeners

ActionView::Base.class_eval do
  def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
    if options && options[:class] == "translation_missing"
      raise "Found a missing translation for #{content_or_options_with_block}"
    end
    super
  end
  # def translate(key, options = {})
  #   options[:raise] = true
  #   I18n.translate(scope_key_by_partial(key), options)
  # end  
  # alias :t :translate
end
