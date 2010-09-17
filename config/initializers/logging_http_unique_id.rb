class HTTPUniqueIDLoggingRackMiddleWare
  def initialize app, options = {}
    @app = app
  end
  def call env
    if request_id = env && env['HTTP_X_UNIQUE_ID']
      RAILS_DEFAULT_LOGGER.info("HTTP_X_UNIQUE_ID: {#{request_id}}")
    else
      RAILS_DEFAULT_LOGGER.warn("HTTP_X_UNIQUE_ID Not Found!")
    end
    @app.call(env)
  end
end

ActionController::Dispatcher.middleware.use HTTPUniqueIDLoggingRackMiddleWare