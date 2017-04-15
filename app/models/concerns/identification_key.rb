module IdentificationKey
  extend ActiveSupport::Concern

  included do
    before_create :add_identification_key
  end

  def add_identification_key
    self.identification_key = SecureRandom.uuid.to_i(32)
  end

end
