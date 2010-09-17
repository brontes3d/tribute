ActiveRecord::Base.class_eval do
  
  def self.truly_in_seperate_transaction
    prev_conn = self.connection
    self.connection_pool.with_connection do |conn|
      self.instance_eval do
        class << self
          attr_accessor :connection
        end
      end
      self.connection = conn
      yield
    end
  ensure
    self.connection = prev_conn    
  end
  
end