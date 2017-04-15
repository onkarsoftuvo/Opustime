class ExpenseProduct < ActiveRecord::Base
  belongs_to :expense
  
  # validates :unit_cost_price , :quantity , presence: true , :allow_nil=> false ,  :allow_blank=> false
  validates :unit_cost_price , :quantity , :presence=> true ,
                                           :numericality => { :only_integer => true , :greater_than=> 0 }, 
                                           :allow_nil=> false , 
                                           :allow_blank=> false
  validates :name , :presence=> true                                             

#  Filters to reflect the changes in product and product stock   
  after_create :set_product_stock_on_create
  before_update :set_product_stock_on_update
  before_destroy :set_product_stock_on_delete
  
  
  def set_product_stock_on_create
    current_user = Thread.current[:user] 
    prod_id = self.prod_id
    product = Product.find(prod_id)

#   To set cost_per_unit in added product   
    new_cost_per_unit = get_cost_per_unit(product)
    new_stock = product.stock_number.to_i + self.quantity.to_i
        
#   setting new stock value and cost per unit here 
    product.update_attributes(stock_number: new_stock, cost_price: new_cost_per_unit)
    
#   creating product stock here   
    product.product_stocks.create(stock_type: "Stock Purchase", quantity: self.quantity.to_i , adjusted_at: DateTime.now.strftime("%e %b %Y,%l:%M%p") , adjusted_by: current_user.full_name)
  end
  
  def set_product_stock_on_update
    current_user = Thread.current[:user] 
    
#   in that if product's name also being changed  
    if self.name.casecmp(self.name_was) != 0

#     For old product 
      prod_id = self.prod_id_was
      product = Product.find(prod_id)
    
      changed_quantity = self.quantity_was
      new_stock = product.stock_number.to_i - changed_quantity
      product.update_attributes(stock_number: new_stock)
      product.product_stocks.create(stock_type: "Expense Adjustment", quantity: (-1*changed_quantity) , adjusted_at: DateTime.now.strftime("%e %b %Y,%l:%M%p") , adjusted_by: current_user.full_name)
      
      # for new product being updated 
      prod_id = self.prod_id
      product = Product.find(prod_id)
      new_cost_per_unit = get_cost_per_unit(product)
      changed_quantity = self.quantity 
      new_stock = product.stock_number.to_i + changed_quantity
      product.update_attributes(stock_number: new_stock, cost_price: new_cost_per_unit)
      product.product_stocks.create(stock_type: "Stock Purchase", quantity: changed_quantity , adjusted_at: DateTime.now.strftime("%e %b %Y,%l:%M%p") , adjusted_by: current_user.full_name)
      
    else
      
#     handling case of expense deletion as well      
      if self.status == self.status_was       
        prod_id = self.prod_id
        product = Product.find(prod_id)
        new_cost_per_unit = get_cost_per_unit(product)
        
    #   quantity_was is a rails method to get difference as attribute updated  
        changed_quantity = self.quantity - self.quantity_was
    
        new_stock = product.stock_number.to_i + changed_quantity
        product.update_attributes(stock_number: new_stock, cost_price: new_cost_per_unit)
        
    #   reflect the same changes in product stock   
        unless changed_quantity ==0
          if changed_quantity > 0 
            product.product_stocks.create(stock_type: "Stock Purchase", quantity: changed_quantity , adjusted_at: DateTime.now.strftime("%e %b %Y,%l:%M%p") , adjusted_by: current_user.full_name) 
          else
            product.product_stocks.create(stock_type: "Expense Adjustment", quantity: changed_quantity , adjusted_at: DateTime.now.strftime("%e %b %Y,%l:%M%p") , adjusted_by: current_user.full_name)
          end
        end
      else
#       To reflect the changes in product and product-stock As expense is deleted   
        prod_id = self.prod_id
        product = Product.find(prod_id)
        changed_quantity = self.quantity
        new_stock = product.stock_number.to_i - changed_quantity
        product.update_attributes(stock_number: new_stock)
        product.product_stocks.create(stock_type: "Expense Removed", quantity: (-1*changed_quantity) , adjusted_at: DateTime.now.strftime("%e %b %Y,%l:%M%p") , adjusted_by: current_user.full_name)
      end
      
    end
    
  end
  
   def set_product_stock_on_delete
    prod_id = self.prod_id
    current_user = Thread.current[:user] 
    product = Product.find(prod_id)
    
    # new_cost_per_unit = get_cost_per_unit(product)
    
#   quantity_was is a rails method to get difference as attribute updated  
    changed_quantity = self.quantity

    new_stock = product.stock_number.to_i - changed_quantity
    product.update_attributes(stock_number: new_stock)
    product.product_stocks.create(stock_type: "Expense Adjustment", quantity: (-1*changed_quantity) , adjusted_at: DateTime.now.strftime("%e %b %Y,%l:%M%p") , adjusted_by: current_user.full_name)
     
  end
  
# Extra afforts to get current user  since can't access current_user and session here    

  def self.current=(user)
    Thread.current[:user] = user
  end
  
  private 
  
  def get_cost_per_unit(product)
    cost_per_unit = self.unit_cost_price
    unless product.tax.nil?
      tax = TaxSetting.find(product.tax).amount
      new_cost_per_unit = (cost_per_unit.to_f)*(1.0+tax/100.0)
    else
      new_cost_per_unit = cost_per_unit
    end
    return new_cost_per_unit
  end
  
end
