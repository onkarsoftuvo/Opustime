class EnateItemsImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform(company,user,business)
    @import_data = JSON.parse(File.read("public/import_files/#{company}/bi.json"))
		@import_data.each do |import|
      item_data = serialize_item_data(import,company)
      if import['enateId'].include? "prod"
        item = Product.find_or_initialize_by(item_data)
      else
        item = BillableItem.find_or_initialize_by(item_data)
      end
      item.save(validate: false)
    end
		import_item_inv_rel(company)
  end

  def import_item_inv_rel(company)
		@import_data = JSON.parse(File.read("public/import_files/#{company}/bti.json"))
		@import_data.each do |import|
			item_rel_data = serialize_item_rel_data(import)
			item_inv_rel = InvoiceItem.find_or_initialize_by(item_rel_data)
			item_inv_rel.save(validate: false)
		end
	end

  def serialize_item_data(item_data,company)
    data={}
    data['enate_id'] = item_data['enateId']
		data['company_id'] = company
    data['name'] = item_data['name']
    data['item_code'] = item_data['code']
    data['price'] = item_data['price']
    data['tax'] = item_data['tax']
    data['status'] = item_data['status'] if item_data['enateId'].include? "prod"
    return data
  end

  def serialize_item_rel_data(inv_item_rel)
		data={}
		if inv_item_rel['enate_billable_item_id'].include? "prod"
			item = Product.find_by(enate_id: inv_item_rel['enate_billable_item_id'])
		else
			item = BillableItem.find_by(enate_id: inv_item_rel['enate_billable_item_id'])
		end
		invoice = Invoice.find_by(enate_id: inv_item_rel['enate_invoice_id'])
		data['item_id'] = item.id if item.present?
		data['item_type'] = item.class.to_s
		data['unit_price'] = inv_item_rel['price']
		data['quantity'] = inv_item_rel['quantity']
		data['total_price'] = inv_item_rel['price'].to_f * inv_item_rel['quantity'].to_i
		data['invoice_id'] = invoice.id if invoice.present?
		# data['enate_id'] = inv_item_rel['enateId']
		return data
	end
end
