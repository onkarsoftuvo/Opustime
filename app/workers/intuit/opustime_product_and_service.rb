module Intuit

  class OpustimeProductAndService < Credentials
    include Intuit::EntityFinder

    def initialize(object_id, object_class, token, secret, realm_id, qbo_credential_id)
      super(token, secret, realm_id)
      # find object (Billable item or Product) as Item on Quickbooks
      @object = object_class.to_s.eql?('Product') ? Product.find_by_id(object_id) : BillableItem.find_by_id(object_id)
      # get company qbo credential object
      @qbo_credential = QuickBookInfo.find_by_id(qbo_credential_id)
    end

    def sync
      # create Quickbooks Item object
      qbo_item = Quickbooks::Item.new(@token, @secret, @realm_id)
      # searching Item or Service on QBO
      search_object_id = search(qbo_item, @object)
      # send data on Quickbooks
      search_object_id.present? ? qbo_item.update_on_qbo(search_object_id, @object, @qbo_credential) : qbo_item.create_on_qbo(@object, @qbo_credential)
    end

    handle_asynchronously :sync, :queue => 'Intuit'

  end
end

