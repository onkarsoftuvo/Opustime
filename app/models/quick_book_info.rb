class QuickBookInfo < ActiveRecord::Base
  belongs_to :company
  # Model Validations
  validates_presence_of :token,:secret,:realm_id
end
