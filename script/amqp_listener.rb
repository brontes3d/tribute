#!/usr/bin/env ruby
# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush

# Load Rails
require File.expand_path('../../config/boot',  __FILE__)

log_dir = File.join(Rails.root, "log", "amqp_messaging")
unless File.exist?(log_dir)
  FileUtils.mkdir_p(log_dir)
end
log_path = File.join(log_dir, "tribute_amqp_listener_#{Process.pid}.log")

load File.join(Rails.root, 'config', 'environment.rb')

messaging_logger = Logger.new(log_path)
Rails.logger.instance_eval do
  class << self
    attr_accessor :messaging_logger
    def add(severity, message = nil, progname = nil, &block)
      messaging_logger.add(severity, message, progname, &block)
    end
  end
end
Rails.logger.messaging_logger = messaging_logger
class << STDERR
  def write(arg)
    Rails.logger.info(arg)
    super(arg)
  end
end
class << STDOUT
  def write(arg)
    Rails.logger.info(arg)
    super(arg)
  end
end
messaging_logger.info("logger setup...")

if PUTS_AMQP_LOGGING
  AmqpListener.set_logger do |level, to_log|
    puts to_log
  end
else
  AmqpListener.set_logger do |level, to_log|
    Rails.logger.send(level, to_log)
  end
end

config_file = File.join(Rails.root, "config", "amqp_daemon.yml")
AmqpListener.run(YAML.load_file(config_file)[Rails.env])
