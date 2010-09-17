if defined?(BRONTES_LOG_DIRECTORY)

  log_dir = File.join(RAILS_ROOT, BRONTES_LOG_DIRECTORY)
  log_prefix = (defined? BRONTES_LOG_PREFIX)? BRONTES_LOG_PREFIX : RAILS_ENV
  log_dir += "/" unless log_dir.ends_with?("/")
  unless File.exist?(log_dir)
    FileUtils.mkdir_p(log_dir)
  end
  PASSENGER_PROCESS_LOGGER_PREFIX = log_dir + log_prefix

  ActionController::Dispatcher.middleware.use RackLoggingPerProc, PASSENGER_PROCESS_LOGGER_PREFIX

end
