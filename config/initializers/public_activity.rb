PublicActivity::Activity.class_eval do
  belongs_to :company, :polymorphic => true
  attr_accessible :company
  
  belongs_to :business
  attr_accessible :business_id
end