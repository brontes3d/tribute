module IdGeneration
  
  def self.get_generator_for(base)
    id_param = base.to_s.underscore + "_number"
    generator_params = IdGenerator.default_generator_params.merge(
                        (base.respond_to?(:id_generator_params) && base.id_generator_params) || {})
    IdGenerator.generator_for("#{base.name}.#{id_param.to_s}", generator_params)
  end
  
  def self.included(base)
    id_param = base.to_s.underscore + "_number"
    
    base.validate do |record|
      if record.send(id_param.to_sym).blank?
        if record.new_record?
          record.generate_new_id
        else
          record.errors.add_on_blank(id_param.to_sym, "Can't be blank")
        end
      end
    end
        
    base.class_eval do
      define_method(:generate_new_id) do
        generator_params = IdGenerator.default_generator_params.merge(
                            (base.respond_to?(:id_generator_params) && base.id_generator_params) || {})
        self.send("#{id_param.to_s}=".to_sym, IdGeneration.get_generator_for(base).next_id)
      end
    end
    
    base.validates_uniqueness_of(id_param.to_sym)
    
    base.as_param id_param
  end
  
end