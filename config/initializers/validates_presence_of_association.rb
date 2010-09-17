# This is so we can validates_presence_of :group on User
# but if :group doesn't exist... add an error on :group_id so that the view renders that element as being in error...
ActiveRecord::Base.class_eval do
  
  def self.validates_presence_of_association(*attr_names)
    configuration = { :on => :save }
    configuration.update(attr_names.extract_options!)

    # can't use validates_each here, because it cannot cope with nonexistent attributes,
    # while errors.add_on_empty can
    send(validation_method(configuration[:on]), configuration) do |record|
      custom_message = configuration[:message]
      for att in [attr_names].flatten
        value = record.respond_to?(att.to_s) ? record.send(att.to_s) : record[att.to_s]
        #TODO: get the foreign key name from the association instead of just appending _id
        record.errors.add("#{att}_id", :blank, :default => custom_message) if value.blank?
      end
    end
  end
  
  
end