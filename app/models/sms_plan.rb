class SmsPlan < ActiveRecord::Base
  belongs_to :owner
  has_many :payment_histories, :as => :paymentable
  scope :active_sms_plan, -> { where(:status => true) }

   validates_presence_of :amount,:no_sms
   validates :amount,:no_sms,:numericality => true
   validates_numericality_of :amount,:no_sms,:only_integer=>true
end
