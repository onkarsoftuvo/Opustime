class SmsSetting < ActiveRecord::Base
  include Reminder::ReadyMade
  include Opustime::Utility
  belongs_to :company
  has_one :sms_credit, :dependent => :destroy

#   later validations 
  validates :sms_alert_no, :default_sms, numericality: {only_integer: true}
  validates :email, format: {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
                             :message => "email doesn't look like an email address"},
            allow_nil: true,
            allow_blank: true

  # validates :mob_no, :allow_nil => true,
  #           :numericality => {only_integer: true},
  #           :length => {:minimum => 10}


  validates_plausible_phone :mob_no ,  :allow_nil => true, :allow_blank=>true

# before_save :normalize_contact_number
  before_validation :normalize_contact_number

  def normalize_contact_number
    self.mob_no = PhonyRails.normalize_number(mob_no, country_code: user_country_code(self))
  end

  #  ending here  -----

end
