class ProductStocksController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_product, :only => [:index, :create]

  load_and_authorize_resource param_method: :params_product_stock
  before_filter :load_permissions

  def index
    prod_stocks = @product.product_stocks.order("adjusted_at desc")
    # result = { :product_stocks=> prod_stocks }
    result = []
    prod_stocks.each do |stock|
      item = {}
      item[:id] = stock.id
      item[:stock_level] = stock.stock_level
      item[:stock_type] = stock.stock_type
      item[:quantity] = stock_quantity_pretty_print(stock)
      item[:adjusted_at] = stock.adjusted_at
      item[:adjusted_by] = stock.stock_adjusted_by
      item[:note] = stock.note
      result << item
    end
    render :json => {:product_stocks => result}

  end

  def create
#     getting values of product stock
#----------- commented by Babar -------------------
#     stock_level= true
#----------- commented by Babar -------------------

    quantity = params["product_stock"]["quantity"].to_i
    #----------- commented by Babar -------------------
    # stock_type = params["product_stock"]["stock_type"]
    #----------- commented by Babar -------------------

    # if params["product_stock"]["stock_level"]=="decreasing"
    #   stock_level=  false
    #
    #   if @product.stock_number > quantity && quantity > 0
    #     quantity = quantity*(-1)
    #   end
    # end
    product_stock = @product.product_stocks.new(params_product_stock)
    if params["product_stock"]["stock_level"]=="increasing"
      if quantity > 0
        if product_stock.valid?
          product_stock.save
          #     reflect changes in stock number of product as well
          unless @product.stock_number.nil?
            @product.stock_number += quantity.to_i
          else
            @product.stock_number = quantity.to_i
          end
          @product.save

          result = {flag: true}
          render :json => result
        else
          show_error_json(product_stock.errors.messages)
        end
      else
        product_stock = ProductStock.new
        product_stock.errors.add(:quantity, "should be valid Product Stock")
        show_error_json(product_stock.errors.messages)
      end
    else
      #----------- commented by Babar -------------------
      # stock_level= false
      #----------- commented by Babar -------------------

      #if @product.stock_number > quantity && quantity > 0
      # quantity = quantity*(-1)
      # end
      if @product.stock_number >= quantity && quantity > 0
        if product_stock.valid?
          product_stock.save
          #     reflect changes in stock number of product as well
          unless @product.stock_number.nil?
            @product.stock_number -= quantity.to_i
          else
            @product.stock_number = quantity.to_i
          end
          @product.save

          result = {flag: true}
          render :json => result
        else
          show_error_json(product_stock.errors.messages)
        end
      else
        product_stock = ProductStock.new
        product_stock.errors.add(:quantity, "should be less than Product Stock or +ve Number")
        show_error_json(product_stock.errors.messages)
      end
    end
  end

  private

  def find_product
    @product = Product.find(params[:product_id])
  end

  def params_product_stock
    params.require(:product_stock).permit('stock_level ,stock_type , quantity , note').tap do |whitelist|
      whitelist[:quantity] = params[:product_stock][:quantity].to_i
      #-------------- Added by Babar --------------------------------
      whitelist[:stock_level] = params[:product_stock][:stock_level].to_s.eql?('increasing') ? true : false
      whitelist[:stock_type] = params[:product_stock][:stock_type]
      whitelist[:note] = params[:product_stock][:note]
      #-------------- Added by Babar --------------------------------
      whitelist[:adjusted_by] = current_user.try(:id)
      whitelist[:adjusted_at] = DateTime.now.strftime('%e %b ,%Y,%l:%M%p')
    end
  end

  def stock_quantity_pretty_print(stock)
    if stock.stock_type.to_s.eql?('Stock Purchase')
      return '+'+stock.quantity.to_s
    elsif stock.stock_type.to_s.eql?('Damaged') || stock.stock_type.to_s.eql?('Out of Date') || stock.stock_type.to_s.eql?('Item Sold')
      return '-'+stock.quantity.to_s
    else
      return stock.quantity.to_s
    end
  end

end
