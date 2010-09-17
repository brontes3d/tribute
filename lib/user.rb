class User
  include ActionController::SessionManagement
  
  attr_reader :username, :user_number, :remote_roles
  
  class << self
    attr_reader :current_user
    def set_current_user_from(hash)
      @current_user = User.new(:username => hash[:username], :user_number => hash[:user_number], :remote_roles => hash[:remote_roles])
    end
  end
  
  def initialize(attributes={}, opts={})
    attributes.each do |k,v|
      begin
        send("#{k}=", v)
      rescue NoMethodError
        raise ArgumentError, "unknown attribute #{k} for #{self.class}"
      end
    end
  end
  
  private
    attr_writer :username, :user_number, :remote_roles
end