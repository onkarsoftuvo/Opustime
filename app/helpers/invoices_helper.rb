module InvoicesHelper
  #   To get invoice item details for show invoice -- three columns only.
  def get_invoice_item_detail(item_id , item_type , item_info , cs_id)
    item =  item_type.constantize.find(item_id) rescue nil
    item_info[:item_code] = item.try(:item_code)
    item_info[:name] = item.try(:name)
    item_info[:item_type] = item_type
    if item_type.casecmp("product")==0
      item_info[:type] = "Product"
    else
      item_info[:concession_type] = get_concession_name(cs_id) 
      if item.try(:type)
        item_info[:type] = "Service"
      else
        item_info[:type] = "Other"
      end
    end
    return item_info
  end
  
  def get_concession_name(cs_id)
    Concession.find(cs_id.to_s).try(:name) rescue nil
  end
  
#   To get Business Info to show on invoice - only three columns - name , address , reg_name , reg_number
  def get_business_detail(business, item_info , status=true)
    # business = Business.find(business_id) rescue nil
    item_info[:business] = {}
    item = {}
    item[:business_id] = business.try(:id)  
    item[:business_name] = business.try(:name)
    item[:address] = business.try(:address)
    item[:state] = business.try(:state)
    item[:country] = business.try(:country)
    item[:pin_code] = business.try(:pin_code)
    item[:reg_name] = business.try(:reg_name)
    item[:reg_number] = business.try(:reg_number)
    item[:web_url] = business.try(:web_url)
    item[:show_contact_info] = status 
    item[:contact_info] = status ? business.try(:contact_info) : nil
    item_info[:business]  = item 
    return item_info
  end 
  
  # def patient_outstanding_balance(patient_id)
    # patient = Patient.find(patient_id) rescue nil
    # outstanding_balance = patient.try(:outstanding_balance).to_f  
    # return outstanding_balance
  # end 
  
  def set_billable_hash(item)
    b_item = {}
    b_item[:item_id] = item.id.to_s
    b_item[:name] = item.name
    b_item[:unit_price] = item.price
    b_item[:concession] = false
    b_item[:quantity] = 1
    b_item[:discount_type_percentage] = true
    return b_item
  end
  
  def get_patient_name(id)
    patient = Patient.where(:id=> id).select("title , first_name , last_name").first rescue nil
    unless patient.nil?
      p_name = patient.title.to_s + " " + patient.first_name.to_s + " " + patient.last_name.to_s  
    else
      p_name = ""
    end
    return p_name
  end
  
  def get_patient_detail_for_edit(patient)
    # patient = Patient.where(:id=> id).select("id ,title, first_name , last_name").first rescue nil
    item = {}
    item[:id] = patient.try(:id)
    item[:title] = patient.try(:title)
    item[:first_name] = patient.try(:first_name)
    item[:last_name] = patient.try(:last_name)
    return item
  end
  
  def get_practitioner_name(id)
   user = User.where(:id=> id).select("title , first_name , last_name").first rescue nil 
   unless user.nil?
      p_name = user.title.to_s + " " + user.first_name.to_s + " " + user.last_name.to_s  
    else
      p_name = ""
    end
    return p_name
  end
  
  # def get_practitioner_detail_for_edit(id)
    # user = User.where(:id=> id).select("id , first_name , last_name").first rescue nil
    # item = {}
    # item[:id] = user.try(:id)
    # item[:first_name] = user.try(:first_name)
    # item[:last_name] = user.try(:last_name)
    # return item
  # end
  
  # def get_business_detail_for_edit(id)
    # business = Business.where(:id=> id).select("id ,name").first rescue nil
    # item = {}
    # item[:id] = business.try(:id)
    # item[:name] = business.try(:name)
    # return item
  # end 
  
  def invoice_id_format(invoice)
    formatted_id = "0"*(6-invoice.id.to_s.length)+ invoice.id.to_s
    #formatted_id = "0"*(6-InvoiceSetting.last.starting_invoice_number.to_s.length)+ InvoiceSetting.last.starting_invoice_number.to_s

    return formatted_id
  end
  
  def add_destroy_key_for_invoice_item(params, invoice)
    existing_invoice_items_ids = invoice.invoice_items.ids
    new_one_invoice_items_ids = []
    params[:invoice][:invoice_items_attributes] = [] if params[:invoice][:invoice_items_attributes].nil?
    params[:invoice][:invoice_items_attributes].each do |invoice_item|
      new_one_invoice_items_ids << invoice_item[:id]  
    end unless params[:invoice][:invoice_items_attributes].nil?
    deletable_invoice_items_ids = existing_invoice_items_ids -new_one_invoice_items_ids
    deletable_invoice_items_ids.each do |del_item|
      item = {}
      item[:id] = del_item
      item[:_destroy] = true
      params[:invoice][:invoice_items_attributes] << item 
    end 
  end
      
  
end
