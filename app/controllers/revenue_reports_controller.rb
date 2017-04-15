class RevenueReportsController < ApplicationController
	respond_to :json
	before_filter :authorize
 	before_action :find_company_by_sub_domain
	before_action :check_authorization , except: [:index]

 	def index
 		result = {}
 		result[:series] = []
 		if params[:filter_type] == "business"
 			result[:obj_names] = all_businesses_names
	        all_businesses_ids.each do |bs|
		        unless bs.first.nil?
		          item = {}
		          obj_name = bs.second
		          total_count = get_revenue(bs.first , params[:invoice_type] , params[:start_date] , params[:end_date] , "bs" , params[:period]) 
		          item[:name] = obj_name.to_s + " ($ #{total_count.sum})" 
		          item[:data] = total_count
		          result[:series] << item  
		        end
		    end
	    elsif params[:filter_type] == "doctor"
	    	result[:obj_names] = all_practitioners_names
	        all_practitioners_ids.each do |doctor|
		        unless doctor.first.nil?
		          item = {}
		          obj_name = doctor.second
		          total_count = get_revenue(doctor.first , params[:invoice_type] , params[:start_date] , params[:end_date] , "dc" , params[:period]) 
		          item[:name] = obj_name.to_s + " ($ #{total_count.sum})" 
		          item[:data] = total_count
		          result[:series] << item  
		        end
	    	end
    	elsif params[:filter_type] == "prod"
	    	result[:obj_names] = all_products_names
	        all_products_ids.each do |product|
		        unless product.first.nil?
		          item = {}
		          obj_name = product.second
		          total_count = get_revenue(product.first , params[:invoice_type] , params[:start_date] , params[:end_date] , "prod", params[:period] ) 
		          item[:name] = obj_name.to_s + " ($ #{total_count.sum})" 
		          item[:data] = total_count
		          result[:series] << item  
		        end
	    	end
    	elsif params[:filter_type] == "b_item"
	    	result[:obj_names] = all_items_names
	        all_items_ids.each do |b_item|
		        unless b_item.first.nil?
		          item = {}
		          obj_name = b_item.second
		          total_count = get_revenue(b_item.first , params[:invoice_type] , params[:start_date] , params[:end_date] , "b_item", params[:period]) 
		          item[:name] = obj_name.to_s + " ($ #{total_count.sum})" 
		          item[:data] = total_count
		          result[:series] << item  
		        end
	    	end
        end 
        result[:weekly_count] = 12 # 
        result[:monthly_count] = 52

 		render :json => result 
 	end 

 	def revenue_list
 		result = {}
 		result[:practitioners] = all_available_practitioners
 		result[:locations] = all_available_locations
 		result[:payment_types] = all_available_payment_types
 		loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
	    ptype_params = params[:p_type].nil? ? nil : params[:p_type].split(",").map{|a| a.to_i}
    	doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(",").map{|a| a.to_i}

 		@payments = get_payments(doctor_params , loc_params  , ptype_params , params[:start_date] , params[:end_date])
		result[:listing] = []

 		@payments.each do |payment|
 			item = {}
			pmt_date = payment.payment_date.to_date.strftime("%A,%d %B %Y")
			at_time = payment.payment_date.strftime(" at %H:%M%p")
			item[:date] = (pmt_date + at_time).to_datetime
			# item[:at_date] = payment.payment_date.strftime(" at %H:%M%p")
			item[:payment_types] = payment.payment_types.map(&:name).join(" , ")
 			item[:location] = payment.business.try(:name)
 			item[:doctors_name] = payment.all_practitioners_names_for_all_involved_invoices.join(" , ")
 			item[:used_products] = payment.used_products.join(" , ")
 			item[:used_service] = payment.used_services.join(" , ")
 			item[:total_payment] = '% .2f'% (payment.get_paid_amount.round(2)).to_f
			result[:listing] << item  			
		end

		# Total invoices details who has payments
		@invoices = get_invoices_filterwise(doctor_params , loc_params  , ptype_params , params[:start_date] , params[:end_date])
		invoice_item = {total_invoces: @invoices.length }
		invoice_item[:total_charges] = '% .2f'% (@invoices.map(&:subtotal).sum.round(2)).to_f
		total_payment = 0
		@invoices.each{|k| total_payment = total_payment + k.total_paid_money_for_invoice }
		invoice_item[:total_payments] = '% .2f'% (total_payment.round(2)).to_f
		outstanding_tot = 0
		@invoices.each{|k| outstanding_tot = outstanding_tot + k.calculate_outstanding_balance }
		invoice_item[:total_outstanding] = '% .2f'% (outstanding_tot.round(2)).to_f
		result[:invoice_details] = invoice_item
		#

 		render :json => result
 	end

 	def revenue_export
 		begin
 			loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
		    ptype_params = params[:p_type].nil? ? nil : params[:p_type].split(",").map{|a| a.to_i}
	    	doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(",").map{|a| a.to_i}
	    	@payments = get_payments(doctor_params , loc_params  , ptype_params , params[:start_date] , params[:end_date])
	    	respond_to do |format|
		        format.html
		        format.csv { render text: @payments.to_csv({}), status: 200 }
		    end
 		rescue Exception => e
 			render :text => e.message  
 		end 
 	end

 	def revenue_pdf
 		loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
	    ptype_params = params[:p_type].nil? ? nil : params[:p_type].split(",").map{|a| a.to_i}
    	doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(",").map{|a| a.to_i}

 		payments = get_payments(doctor_params , loc_params  , ptype_params , params[:start_date] , params[:end_date])
 		@result = []
 		payments.each do |payment|
 			item = {}
 			item[:date]	 = payment.payment_date.strftime("%A , %d %b %Y")
 			item[:payment_types] = payment.payment_types.map(&:name).join(" , ")
 			item[:location] = payment.business.try(:name)
 			item[:doctors_name] = payment.all_practitioners_names_for_all_involved_invoices.join(" , ")
 			item[:used_products] = payment.used_products.join(" , ")
 			item[:used_service] = payment.used_services.join(" , ")
 			item[:total_payment] = payment.get_paid_amount
			@result << item  			
 		end
 		respond_to do |format|
	      format.html
	      format.pdf do
	        render :pdf => "pdf_name.pdf" , 
	               :layout => '/layouts/pdf.html.erb' ,
	               :disposition => 'inline' ,
	               :template    => "/revenue_reports/revenue_pdf.pdf.erb",
	               :show_as_html => params[:debug].present? ,
	               :footer=> { right: '[page] of [topage]' }
	      end 
	    end

 	end

 	private

	def check_authorization
		authorize! :payment_summary , :payment_report
	end

 	def all_businesses_names
		@company.businesses.map(&:name) 		
 	end

 	def all_businesses_ids
	    @company.businesses.pluck("id , name")
	end

	def get_revenue(obj_id ,invoice_type , start_date , end_date , obj_type , period="week") 
		result = []
		if period == "week"
			(start_date.to_date .. end_date.to_date).each do |dt|
		    	result <<  total_revenue(obj_id , dt , obj_type , invoice_type)   
		    end	
	    elsif period == "month"
	    	(start_date.to_date .. end_date.to_date).each do |dt|
		    	result <<  total_revenue(obj_id , dt , obj_type , invoice_type)   
		    end
		elsif period == "year"
			count_month = 1
	     	result = []
	        st_date = start_date.to_date
	        while count_month <= 12
	        	result <<  total_revenue_monthly(obj_id , obj_type, st_date , (st_date + 1.month - 1.day) , invoice_type )
	        	count_month = count_month + 1
	        	st_date = st_date + 1.month
	      	end

		end 
		
		return result
	end

	def all_practitioners_names
	    result = []
			if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
				doctors = @company.users.doctors.where(['users.id = ?' , current_user.id])
			else
				doctors = @company.users.doctors
			end

			doctors.each do |dc|
	      result << dc.full_name_with_title
	    end
	    return result 
    end

    def all_practitioners_ids
	    result = []
			if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
				doctors = @company.users.doctors.where(['users.id = ?' , current_user.id])
			else
				doctors = @company.users.doctors
			end

	    doctors.each do |dc|
	      item = []
	      item << dc.id
	      item << dc.full_name_with_title
	      result << item
	    end
	    return result 
	end

	def all_products_names
		@company.products.active_products.map(&:name)		
	end

	def all_products_ids
		@company.products.active_products.pluck("id , name")
	end

	def all_items_names
		@company.billable_items.map(&:name)	
	end

	def all_items_ids
		@company.billable_items.pluck("id , name ")		
	end

	def total_revenue(obj_id , dt , obj_type , invoice_type)   
		amount  = 0
		invoices = @company.invoices.joins(:business).where("businesses.id = ? AND DATE(invoices.issue_date) = ?" , obj_id , dt.to_date) if obj_type == "bs"
		if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
			invoices = @company.invoices.joins(:user).where("users.id = ? AND  users.id = ? AND DATE(invoices.issue_date) = ?" , current_user.id , obj_id , dt.to_date) if obj_type == "dc"
		else
			invoices = @company.invoices.joins(:user).where("users.id = ? AND DATE(invoices.issue_date) = ?" , obj_id , dt.to_date) if obj_type == "dc"
		end


		invoices = @company.invoices.joins(:invoice_items).where("invoice_items.item_id = ? AND invoice_items.item_type = ? AND DATE(invoices.issue_date) = ? " , obj_id , "Product",  dt) if obj_type == "prod"
		invoices = @company.invoices.joins(:invoice_items).where("invoice_items.item_id = ? AND invoice_items.item_type = ? AND DATE(invoices.issue_date) = ? " , obj_id , "BillableItem",  dt) if obj_type == "b_item"

		invoices.each do |invoice|
			if invoice_type.to_i == 0
				amount = amount + invoice.calculate_outstanding_balance
			elsif invoice_type.to_i == 1
				amount = amount + invoice.total_paid_money_for_invoice
			else
				amount = amount + invoice.total_paid_money_for_invoice		
			end
		end
		return amount					
	end

	def total_revenue_monthly(obj_id , obj_type, st_date , end_date , invoice_type )
		amount  = 0
		invoices = @company.invoices.joins(:business).where("businesses.id = ? AND DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ?" , obj_id , st_date.to_date , end_date.to_date) if obj_type == "bs"
		if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
			invoices = @company.invoices.joins(:user).where("users.id = ? AND users.id = ? AND DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ?" , current_user.id  , obj_id , st_date.to_date , end_date.to_date) if obj_type == "dc"
		else
			invoices = @company.invoices.joins(:user).where("users.id = ? AND DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ?" , obj_id , st_date.to_date , end_date.to_date) if obj_type == "dc"
		end


		invoices = @company.invoices.joins(:invoice_items).where("invoice_items.item_id = ? AND invoice_items.item_type = ? AND DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ? " , obj_id , "Product", st_date.to_date , end_date.to_date) if obj_type == "prod"
		invoices = @company.invoices.joins(:invoice_items).where("invoice_items.item_id = ? AND invoice_items.item_type = ? AND DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ? " , obj_id , "BillableItem",  st_date.to_date , end_date.to_date) if obj_type == "b_item"

		invoices.each do |invoice|
			if invoice_type.to_i == 0
				amount = amount + invoice.total_paid_money_for_invoice	if invoice.calculate_outstanding_balance > 0 
			elsif invoice_type.to_i == 1
				amount = amount + invoice.total_paid_money_for_invoice	if invoice.calculate_outstanding_balance == 0
			else
				amount = amount + invoice.total_paid_money_for_invoice		
			end
		end
		return amount	
	end	

	def all_available_practitioners
	    result = []
	    @company.users.doctors.each do |doctor|
	    	item = {}
	      	item[:id] = doctor.id
	      	item[:name] = doctor.full_name_with_title
	      	result << item 
	    end
	   return result
	end

	def all_available_locations
	    result = []
	    @company.businesses.each do |business|
	      item = {}
	      item[:id] = business.id
	      item[:name] = business.name
	      result << item 
	    end
	    return result
	end

	def all_available_payment_types
	    result = []
	    @company.payment_types.each do |p_type|
	      item = {}
	      item[:id] = p_type.id
	      item[:name] = p_type.name
	      result << item 
	    end
	    return result
	end

	def get_payments(doctor , loc , ptype , start_date , end_date)
		result = []
	    unless start_date.nil? && end_date.nil?
	      st_date = start_date.to_date
	      end_date = end_date.to_date
	      if loc.nil? && ptype.nil? && doctor.nil?  
	        result = @company.payments.active_payment.where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      elsif !(loc.nil?) && ptype.nil? && doctor.nil?
	        result = @company.payments.active_payment.joins(:invoices=> [:business]).where(["businesses.id IN (?)" , loc]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      elsif (loc.nil?) && !(ptype.nil?) && doctor.nil?    
	        result = @company.payments.active_payment.joins(:payment_types).where(["payment_types.id IN (?)" , ptype]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      elsif (loc.nil?) && (ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:invoices=> [:user]).where(["users.id IN (?)" , doctor]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      elsif !(loc.nil?) && !(ptype.nil?) && doctor.nil?
	        result = @company.payments.active_payment.joins( :payment_types , :invoices=> [:business]).where(["businesses.id IN (?) AND payment_types.id IN (?)" , loc , ptype]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      elsif !(loc.nil?) && (ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:invoices => [:business , :user]).where(["businesses.id IN (?) AND users.id IN (?) " , loc , doctor]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      elsif (loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:payment_types , :invoices=>[:user] ).where(["users.id IN (?) AND payment_types.id IN (?) " , doctor , ptype]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      elsif !(loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:payment_types , :invoices=>[:user , :business] ).where(["users.id IN (?) AND payment_types.id IN (?) AND businesses.id IN (?) " , doctor , ptype , loc]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
	      end  
	      return result.uniq   
	    else
	      if loc.nil? && ptype.nil? && doctor.nil?  
	        result = @company.payments.active_payment.where(["DATE(payment_date) = ? AND DATE(payment_date) = ? " , Date.today , Date.today])
	      elsif !(loc.nil?) && ptype.nil? && doctor.nil?
	        result = @company.payments.active_payment.joins(:invoices=> [:business]).where(["businesses.id IN (?)" , loc])
	      elsif (loc.nil?) && !(ptype.nil?) && doctor.nil?    
	        result = @company.payments.active_payment.joins(:payment_types).where(["payment_types.id IN (?)" , ptype])
	      elsif (loc.nil?) && (ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:invoices=> [:user]).where(["users.id IN (?)" , doctor])
	      elsif !(loc.nil?) && !(ptype.nil?) && doctor.nil?
	        result = @company.payments.active_payment.joins(:payment_types , :invoices=> [:business]).where(["businesses.id IN (?) AND payment_types.id IN (?)" , loc , ptype])
	      elsif !(loc.nil?) && (ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:invoices => [:business , :user]).where(["businesses.id IN (?) AND users.id IN (?) " , loc , doctor])
	      elsif (loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:payment_types , :invoices=>[:user]).where(["users.id IN (?) AND payment_types.id IN (?) " , doctor , ptype])
	      elsif !(loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
	        result = @company.payments.active_payment.joins(:payment_types , :invoices=>[:user , :business] ).where(["users.id IN (?) AND payment_types.id IN (?) AND businesses.id IN (?) " , doctor , ptype , loc])
	      end  
	      return result.order('DATE(payment_date) asc')
	    end
	end

	def get_invoices_filterwise(doctor , loc , ptype , start_date , end_date)
		result = []
		unless start_date.nil? && end_date.nil?
			st_date = start_date.to_date
			end_date = end_date.to_date
			if loc.nil? && ptype.nil? && doctor.nil?
				# result = @company.payments.active_payment.where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
				result = @company.invoices.active_invoice.joins(:payments).where(["DATE(payments.payment_date) >= ? AND DATE(payments.payment_date) <= ? " , st_date.to_date , end_date.to_date])
			elsif !(loc.nil?) && ptype.nil? && doctor.nil?
				result = @company.invoices.active_invoice.joins(:payments , :business).where(["businesses.id IN (?)" , loc]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
			elsif (loc.nil?) && !(ptype.nil?) && doctor.nil?
				result = @company.invoices.active_invoice.joins(:payments => [:payment_types]).where(["payment_types.id IN (?)" , ptype]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
			elsif (loc.nil?) && (ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:payments  , :user).where(["users.id IN (?)" , doctor]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
			elsif !(loc.nil?) && !(ptype.nil?) && doctor.nil?
				result = @company.invoices.active_invoice.joins(:business ,  :payments => [:payment_types]).where(["businesses.id IN (?) AND payment_types.id IN (?)" , loc , ptype]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
			elsif !(loc.nil?) && (ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:business , :user , :payments).where(["businesses.id IN (?) AND users.id IN (?) " , loc , doctor]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
			elsif (loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:user , :payments => [:payment_types] ).where(["users.id IN (?) AND payment_types.id IN (?) " , doctor , ptype]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
			elsif !(loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:user , :business , :payments => [:payment_types] ).where(["users.id IN (?) AND payment_types.id IN (?) AND businesses.id IN (?) " , doctor , ptype , loc]).where(["DATE(payment_date) >= ? AND DATE(payment_date) <= ? " , st_date.to_date , end_date.to_date])
			end
			return result.uniq
		else
			if loc.nil? && ptype.nil? && doctor.nil?
				result = @company.invoices.active_invoice.joins(:payments).where(["DATE(payments.payment_date) = ? AND DATE(payments.payment_date) = ? " , Date.today , Date.today])
			elsif !(loc.nil?) && ptype.nil? && doctor.nil?
				result = @company.invoices.active_invoice.joins(:business).where(["businesses.id IN (?)" , loc])
			elsif (loc.nil?) && !(ptype.nil?) && doctor.nil?
				result = @company.invoices.active_invoice.joins(:payments => [:payment_types]).where(["payment_types.id IN (?)" , ptype])
			elsif (loc.nil?) && (ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:user).where(["users.id IN (?)" , doctor])
			elsif !(loc.nil?) && !(ptype.nil?) && doctor.nil?
				result = @company.invoices.active_invoice.joins(:business , :payments => [:payment_types] ).where(["businesses.id IN (?) AND payment_types.id IN (?)" , loc , ptype])
			elsif !(loc.nil?) && (ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:business , :user).where(["businesses.id IN (?) AND users.id IN (?) " , loc , doctor])
			elsif (loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:user , :payments=> [:payment_types] ).where(["users.id IN (?) AND payment_types.id IN (?) " , doctor , ptype])
			elsif !(loc.nil?) && !(ptype.nil?) && !(doctor.nil?)
				result = @company.invoices.active_invoice.joins(:user , :business , :payments => [:payment_types]  ).where(["users.id IN (?) AND payment_types.id IN (?) AND businesses.id IN (?) " , doctor , ptype , loc])
			end
			return result
		end
	end
	
end
