class BillableItemsConcession < ActiveRecord::Base
  belongs_to :billable_item
  belongs_to :concession
  
  validates :value ,  :numericality => {:greater_than_or_equal_to => 0} , allow_nil: true , allow_blank: true
  
end
