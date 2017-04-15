class ContactNo < ActiveRecord::Base
  belongs_to :contact
  include Opustime::Utility
  validates_plausible_phone :contact_number ,
                            :allow_nil => true

  before_validation :normalize_contact_number

  def normalize_contact_number
    self.contact_number = PhonyRails.normalize_number(contact_number, country_code: user_country_code(contact))
  end

end

