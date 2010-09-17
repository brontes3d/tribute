module AuditCreatedByUser
  
  def self.included(mod)
    mod.class_eval do
      before_create :set_created_by_user
    end
  end
  
  def set_created_by_user
    if User.current_user
      self.created_by_username= User.current_user.username
      self.created_by_user_number= User.current_user.user_number
    end
  end
  
end