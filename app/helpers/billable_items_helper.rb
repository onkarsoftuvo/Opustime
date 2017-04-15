module BillableItemsHelper
  
  # def get_billable_item(billable_item)
    # result ={}
    # result[:id] =  billable_item.id
    # result[:item_code] =  billable_item.item_code
    # result[:name] =  billable_item.name
    # result[:price] =  billable_item.price if billable_item.price.nil?
    # get_price_detail(billable_item.price ,billable_item.tax , billable_item.include_tax, result) unless billable_item.price.nil?
    # result[:include_tax] =  false
    # result[:tax] =  billable_item.tax
    # result[:item_type] =  billable_item.item_type
    # result[:concession_price] =  billable_item.concession_price
    # return result    
  # end
  
  def get_price_detail(price ,tax , include_tax, item_hash)
    unless tax.nil? 
      unless tax.to_s.casecmp("N/A") == 0 
        tax_amount = TaxSetting.find(tax).amount rescue nil
      else 
        tax_amount = nil
      end   
    else 
      tax_amount = nil
    end 
    
    if include_tax == true && !tax_amount.nil?
      price_exc_tax = ((price.to_f)/(1 + (tax_amount/100.0))).round(2)
      price_inc_tax = price 
    else
      if !tax_amount.nil?
        price_exc_tax = price
        price_inc_tax = ((price.to_f)*(1 + (tax_amount/100.0))).round(2)
      else
        price_exc_tax = price
        price_inc_tax = price
      end
    end
    price = price_exc_tax
    
    item_hash[:price] = price
    item_hash[:price_exc_tax] = price_exc_tax
    item_hash[:price_inc_tax] = price_inc_tax
    return item_hash
    
  end
  
end
