class PatientContact < ActiveRecord::Base
  include Opustime::Utility
  belongs_to :patient
  # validates :contact_no, format: { with: /\A(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}\z/,
  #                             message: "Invalid contact number"}

  # validates_format_of :contact_no,
  #                     :with => /\A\+\d+/,
  #                     :message => "Invalid contact number."
  # validates_plausible_phone :contact_no

  before_save :normalize_contact_number
  # before_validation :normalize_contact_number

  def normalize_contact_number
    self.contact_no = PhonyRails.normalize_number(contact_no, country_code: user_country_code(patient))
    self.contact_no
  end

end

