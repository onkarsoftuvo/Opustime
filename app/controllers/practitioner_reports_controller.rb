class PractitionerReportsController < ApplicationController
	respond_to :json
	before_filter :authorize
 	before_action :find_company_by_sub_domain , :only =>[:index , :list_info , :export , :generate_pdf]
	before_action :check_authorization , except: [:index]
  
  	def index
		result = {}
		result[:series] = []
		if params[:filter_type].present? && params[:filter_type] == "atype"
			item = {}
			result[:obj_names] = get_appnt_types
		    all_appointment_types_ids.each do |appnt_type|
		    	unless appnt_type.first.nil?
		    		item = {}
            obj_name = appnt_type.second
            total_count = get_doctors_for_specific_appnt_type(appnt_type.first)
            item[:name] =   obj_name.to_s + "(#{total_count})"
            item[:data] = total_count
            result[:series] << item  
		      end
		    end
		elsif params[:filter_type].present? && params[:filter_type] == "loc"
			item = {}
			result[:obj_names] = get_locations
		    all_businesses_ids.each do |bs_elem|
		    	unless bs_elem.first.nil?
		    		item = {}
		            obj_name = bs_elem.second
		            total_count = get_doctors_for_specific_loc(bs_elem.first)
		            item[:name] =   obj_name.to_s + " (#{total_count})"
		            item[:name] =   obj_name.to_s + "(#{total_count})"
		            item[:data] = total_count
		            result[:series] << item  
		        end
		    end
	    elsif params[:filter_type].present? && params[:filter_type] == "item"
	    	item = {}
			result[:obj_names] = items_name
		    all_items_id.each do |b_item|
		    	unless b_item.first.nil?
		    		item = {}
		            obj_name = b_item.second
		            total_count = get_doctors_for_specific_b_item(b_item.first)
		            item[:name] =   obj_name.to_s + " (#{total_count})"
		            item[:name] =   obj_name.to_s + "(#{total_count})"
		            item[:data] = total_count
		            result[:series] << item  
		        end
		    end
		end
		render :json => result
  	end	
 
  	def list_info
		result = {}
		# Getting filters data 
    	result[:services] = all_available_services
    	result[:locations] = all_available_locations
    	result[:service_items] = get_billable_items
    	start_date = params[:st_date].to_date unless params[:st_date].nil?
    	end_date = params[:end_date].to_date unless params[:end_date].nil?
	    # Getting listing values 
	    result[:doctors_listing_info] = []

    	loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
    	service_params = params[:service].nil? ? nil : params[:service].split(",").map{|a| a.to_i}
    	item_params = params[:item].nil? ? nil : params[:item].split(",").map{|a| a.to_i}
	    @doctors = get_doctors_info(loc_params , service_params , item_params, start_date , end_date)
	    @doctors.each do |doctor|
	    	item = {}
	    	item[:dc_full_name] = doctor.full_name_with_title
	    	item[:appnt_no] = doctor.total_active_appointments
	    	item[:revenue] = '% .2f'% (doctor.total_revenues.round(2)).to_f
	    	item[:rised_invoices] = '% .2f'% (doctor.rised_invoices_amount.round(2)).to_f
	    	item[:closed_invoices] = '% .2f'% (doctor.closed_invoices_amount.round(2)).to_f
	    	item[:opened_invoices] = '% .2f'% (doctor.opened_invoices_amount.round(2)).to_f

	    	result[:doctors_listing_info] << item 
	    end
		render :json => result
  	end 

  	def export
  		begin
        start_date = params[:st_date].to_date unless params[:st_date].nil?
        end_date = params[:end_date].to_date unless params[:end_date].nil?
	  		loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
	    	service_params = params[:service].nil? ? nil : params[:service].split(",").map{|a| a.to_i}
	    	item_params = params[:item].nil? ? nil : params[:item].split(",").map{|a| a.to_i}

		    @doctors = get_doctors_info(loc_params , service_params , item_params, start_date , end_date)
		    respond_to do |format|
		    	format.html
		        format.csv { render text: @doctors.to_csv , status: 200 }
	        end
  		rescue Exception => e
  			render :text => e.message  	
  		end 
  	end

    def generate_pdf
      @result = []
      start_date = params[:st_date].to_date unless params[:st_date].nil?
      end_date = params[:end_date].to_date unless params[:end_date].nil?
      loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
      service_params = params[:service].nil? ? nil : params[:service].split(",").map{|a| a.to_i}
      item_params = params[:item].nil? ? nil : params[:item].split(",").map{|a| a.to_i}

      doctors = get_doctors_info(loc_params , service_params , item_params, start_date , end_date)
      doctors.each do |doctor|
        item = {}
        item[:dc_full_name] = doctor.full_name_with_title
        item[:appnt_no] = doctor.total_active_appointments
        item[:revenue] = (doctor.total_revenues)
        item[:rised_invoices] = doctor.rised_invoices_amount
        item[:closed_invoices] = doctor.closed_invoices_amount
        item[:opened_invoices] = doctor.opened_invoices_amount
        @result << item 
      end

      respond_to do |format|
        format.html
        format.pdf do
          render :pdf => 'pdf_name.pdf' ,
                 :layout => '/layouts/pdf.html.erb' ,
                 :disposition => 'inline' ,
                 :template    => '/practitioner_reports/generate_pdf',
                 :show_as_html => params[:debug].present? ,
                 :footer=> { right: '[page] of [topage]' }
        end
      end

    end

  	

  	private

		def check_authorization
			authorize! :practitioner_revenue , :practitioner_report
		end

  	def get_appnt_types
  		@company.appointment_types.map(&:name)
  	end 

  	def all_appointment_types_ids
		@company.appointment_types.pluck('id , name ')
	end 

	def get_doctors_for_specific_appnt_type(appnt_type_id)
		if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
			@company.users.doctors.joins(:appointment_types).where(["users.id = ? AND appointment_types.id = ? ", current_user.id , appnt_type_id]).uniq.count
		else
			@company.users.doctors.joins(:appointment_types).where(["appointment_types.id = ? ", appnt_type_id]).count
		end

	end
    
    # Getting Practitioners info location wise
	def get_locations
		@company.businesses.map(&:name)
	end

	def all_businesses_ids
		@company.businesses.pluck('id , name')
	end

	def get_doctors_for_specific_loc(bs_id)
		if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
			@company.users.doctors.joins(:practitioner_avails).where(["users.id = ? AND practitioner_avails.business_id = ? ", current_user.id  , bs_id ]).uniq.count
		else
			@company.users.doctors.joins(:practitioner_avails).where(["practitioner_avails.business_id = ? ",  bs_id ]).uniq.count
		end

	end

	def all_available_services
	    result = []
	    @company.appointment_types.each do |service|
	      item = {}
	      item[:id] = service.id
	      item[:name] = service.name
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

    def get_billable_items
    	result = []
    	@company.billable_items.each do |b_item|
    		item = {}
    		item[:id] = b_item.id
    		item[:name] = b_item.name
    		result << item
    	end
    	return result
    end

    def items_name
   		@company.billable_items.map(&:name)
    end

    def all_items_id
    	@company.billable_items.pluck('id , name')
    end

    def get_doctors_for_specific_b_item(b_item_id)
			if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
				@company.users.doctors.joins(:invoices=>[:invoice_items]).where("users.id = ? AND invoice_items.item_id = ? AND invoice_items.item_type = ? " , current_user.id , b_item_id , "BillableItem").uniq.count
			else
				@company.users.doctors.joins(:invoices=>[:invoice_items]).where("invoice_items.item_id = ? AND invoice_items.item_type = ? " , b_item_id , "BillableItem").uniq.count
			end
    end

    def get_doctors_info(loc , service , item , start_date , end_date)
    	result = []	
    	if loc.nil? && service.nil? && item.nil?
    		if start_date.nil? && end_date.nil?
    			result = @company.users.doctors.joins(:invoices).where(["invoices.issue_date >= ? AND invoices.issue_date <= ? " , Date.today , Date.today]).uniq
				else
    			result = @company.users.doctors.joins(:invoices).where(["DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ? " , start_date , end_date]).uniq
				end
			elsif !(loc.nil?) && service.nil? && item.nil?
      		if start_date.nil? && end_date.nil?
      			result = @company.users.doctors.joins(:practitioner_avails).where(["practitioner_avails.business_id IN (?)", loc]).uniq
					else
      			result = @company.users.doctors.joins(:invoices , :practitioner_avails).where(["practitioner_avails.business_id IN (?) AND invoices.issue_date >= ? AND invoices.issue_date <= ? ", loc , start_date , end_date]).uniq
      		end
      		
			elsif (loc.nil?) && !(service.nil?) && item.nil?
      		if start_date.nil? && end_date.nil?
      			result = @company.users.doctors.joins(:appointment_types).where(["appointment_types.id IN (?)",service]).uniq
					else
      			result = @company.users.doctors.joins( :invoices , :appointment_types).where(["appointment_types.id IN (?) AND invoices.issue_date >= ? AND invoices.issue_date <= ?",service , start_date , end_date]).uniq
      		end
        	
			elsif (loc.nil?) && (service.nil?) && !(item.nil?)
      		if start_date.nil? && end_date.nil?
      			result = @company.users.doctors.joins(:invoices=>[:invoice_items]).where("invoice_items.item_id IN (?) AND invoice_items.item_type = ? " , item , "BillableItem").uniq
					else
      			result = @company.users.doctors.joins(:invoices=>[:invoice_items]).where("invoice_items.item_id IN (?) AND invoice_items.item_type = ? AND invoices.issue_date >= ? AND invoices.issue_date <= ? " , item , "BillableItem" , start_date, end_date).uniq
      		end
        	
			elsif !(loc.nil?) && !(service.nil?) && item.nil?
      		if start_date.nil? && end_date.nil?
      			result = @company.users.doctors.joins(:practitioner_avails , :appointment_types).where(["practitioner_avails.business_id IN (?) AND appointment_types.id IN (?)", loc , service]).uniq
					else
      			result = @company.users.doctors.joins(:invoices , :practitioner_avails , :appointment_types ).where(["practitioner_avails.business_id IN (?) AND appointment_types.id IN (?) AND invoices.issue_date >= ? AND invoices.issue_date <= ? ", loc , service , start_date , end_date]).uniq
      		end
        	
			elsif !(loc.nil?) && (service.nil?) && !(item.nil?)
      		if start_date.nil? && end_date.nil?
      			result = @company.users.doctors.joins(:practitioner_avails , :invoices=>[:invoice_items]).where("practitioner_avails.business_id IN (?) AND invoice_items.item_id IN (?) AND invoice_items.item_type = ? " ,  loc ,  item , "BillableItem").uniq
					else
      			result = @company.users.doctors.joins(:practitioner_avails ,  :invoices=>[:invoice_items]).where("practitioner_avails.business_id IN (?) AND invoice_items.item_id IN (?) AND invoice_items.item_type = ? AND invoices.issue_date >= ? AND invoices.issue_date <= ? " ,  loc ,  item , "BillableItem" , start_date , end_date).uniq
      		end
        	
			elsif (loc.nil?) && !(service.nil?) && !(item.nil?)
      		if start_date.nil? && end_date.nil?
      			result = @company.users.doctors.joins(:appointment_types , :invoices=>[:invoice_items]).where("appointment_types.id IN (?) AND invoice_items.item_id IN (?) AND invoice_items.item_type = ? " ,  service ,  item , "BillableItem").uniq
					else
      			result = @company.users.doctors.joins(:appointment_types  , :invoices=>[:invoice_items]).where("appointment_types.id IN (?) AND invoice_items.item_id IN (?) AND invoice_items.item_type = ? AND invoices.issue_date >= ? AND invoices.issue_date <= ? " ,  service ,  item , "BillableItem" , start_date , end_date).uniq
      		end
        	
			elsif !(loc.nil?) && !(service.nil?) && !(item.nil?)
      		if start_date.nil? && end_date.nil?
      			result = @company.users.doctors.joins(:appointment_types , :practitioner_avails , :invoices=>[:invoice_items]).where("appointment_types.id IN (?) AND practitioner_avails.business_id IN (?) AND invoice_items.item_id IN (?) AND invoice_items.item_type = ? " , service ,  loc ,  item , "BillableItem").uniq
					else
    				result = @company.users.doctors.joins(:appointment_types  , :practitioner_avails , :invoices=>[:invoice_items]).where("appointment_types.id IN (?) AND practitioner_avails.business_id IN (?) AND invoice_items.item_id IN (?) AND invoice_items.item_type = ? AND invoices.issue_date >= ? AND invoices.issue_date <= ?  " , service ,  loc ,  item , "BillableItem" , start_date , end_date).uniq
    				# result = @company.users.doctors.joins(:appointment_types  , :practitioner_avails , :invoices=>[:invoice_items]).where("appointment_types.id IN (?) AND practitioner_avails.business_id IN (?) AND invoice_items.item_id IN (?) AND invoice_items.item_type = ? " , service ,  loc ,  item , "BillableItem" ).where("DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ?", start_date , end_date)

					end
      	end 
      	return result   
    end

end
