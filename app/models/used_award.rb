class UsedAward < ActiveRecord::Base
  
  belongs_to :granted_award
  belongs_to :invoice
  
  validates_presence_of :granted_award
  validates_presence_of :invoice
  
end