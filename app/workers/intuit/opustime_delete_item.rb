module Intuit
  class OpustimeDeleteItem < Credentials
    include Intuit::EntityFinder

    def initialize(object_id, object_class, token, secret, realm_id)
      super(token, secret, realm_id)
      @object = object_class.to_s.eql?('Product') ? Product.find_by_id(object_id) : BillableItem.find_by_id(object_id)
      @object_class = object_class
    end

    def sync_delete
      qbo_item = Quickbooks::Item.new(@token, @secret, @realm_id)
      # searching item on QBO
      search_object_id = search(qbo_item, @object)
      qbo_item.delete_on_qbo(@object.qbo_id, @object) if search_object_id.present?
    end

    handle_asynchronously :sync_delete, :queue => 'Intuit'

  end
end
