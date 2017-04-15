module Intuit
  class OpustimePatient < Credentials
    include Intuit::EntityFinder
    def initialize(patient_id, token, secret, realm_id)
      super(token, secret, realm_id)
      @patient = Patient.find_by_id(patient_id)
    end

    def sync
      # create Quickbooks customer object
      customer = Quickbooks::Customer.new(@token, @secret, @realm_id)
      # searching patient on QBO
      search_object_id = search(customer,@patient)
      # send data on Quickbooks
      search_object_id.present? ? customer.update_on_qbo(search_object_id, @patient) : customer.create_on_qbo(@patient)
    end

    handle_asynchronously :sync, :queue => 'Intuit'

  end
end
