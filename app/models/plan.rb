class Plan < ActiveRecord::Base
  belongs_to :owner
  # has_many :subscriptions 
  # has_one :company , :through=> :subscriptions
  has_many :payment_histories, :as => :paymentable
  scope :active_plan, -> { where(status: true)}

  validates_presence_of :name,:no_doctors,:price,:category
  validates :price,:numericality => true
  validates_numericality_of :no_doctors,:only_integer=>true

end
