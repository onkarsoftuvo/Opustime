class Admin::AdminBusinessController < ApplicationController
	layout "application_admin"
	before_action :admin_authorize
	def new
		@business = @company.businesses.new
		render :json=> @business
		end
		def create
		business = @company.businesses.new(business_params)
		if business.valid?
			business.save
			# set_availability(business)  # set user availability for this business
			render :json=> {flag: true , :business_id => business.id }
		else
			show_error_json(business.errors.messages)
		end

	end

	def edit
	# company  =Company.find(params[:setting_id])
	business = Business.select("id ,name , address , city , state , pin_code, country, reg_name , reg_number , web_url , contact_info, online_booking,internal_info").find(params[:id])
	render :json=> business 

	end

	def update
	
	if  params[:business].keys.include?"comming_from"
		@business = Business.find(params[:id])
		
		@business.update_attributes(business_params)
		if 	@business.valid? 
			if params[:business][:web_url].nil?
				@company = @business.company
				owner_name =  params[:account][:first_name]
				@account = @company.account
				unless @account.nil? && owner_name.nil?
					@account.update_attributes(first_name: owner_name)
				end
			end
		end
		unless params[:business][:web_url].nil?
			if @business.save
				respond_to do |format|
				#flash[:success] = "User was successfully updated."
					format.html { redirect_to  "/business/#{@business.id}/edit_business", notice: 'Business was successfully updated.' }
				end
			else
				#9 = @business.errors.messages
				respond_to do |format|
				#flash[:success] = "User was successfully updated."
					custom_err_msg =  @business.errors.messages.keys.first.to_s
					format.html { redirect_to  "/business/#{@business.id}/edit_business", alert: custom_err_msg  + " " + 'should be valid format' }
				end	
			end
		else
			respond_to do |format|
			#flash[:success] = "User was successfully updated."
				format.html { redirect_to  "/business/#{@business.company.id}/details", notice: 'Business was successfully updated.' }
		    end
		end
	else
		@company = Company.find(params[:id])
		if @company.online_booking.allow_online == true && is_business_having_all_infos(params) == true
		 	bsn = Business.new
		  	bsn.errors.add(:online_booking, "Full details must be provided if online bookings is enabled.")
		  	show_error_json(bsn.errors.messages)
		elsif @company.online_booking.allow_online == true && is_business_having_all_infos(params) == false
		 	business =  Business.find(params[:id])
		  	is_update = business.update(business_params)
		  	if is_update
		    	@basic_info  = Business.select("id, name, address, city , state, pin_code , country , reg_name , reg_number , web_url , contact_info , online_booking ").find(params[:id]) 
		    	render :json=>{:flag=> true , data: @basic_info}
		 	else
		    	business.company.mark_for_destruction
		    	show_error_json(business.errors.messages)
		  	end
		else
			business =  Business.find(params[:id])
			is_update = business.update(business_params)
			if is_update
		  		@basic_info  = Business.select("id, name, address, city , state, pin_code , country , reg_name , reg_number , web_url , contact_info , online_booking ").find(params[:id]) 
		  		render :json=>{:flag=> true , data: @basic_info}
			else
		  		business.company.mark_for_destruction
		  		show_error_json(business.errors.messages)
			end
		end
	end
	end

	def destroy
	business = Business.find(params[:id])
	# business.users.map{|user| user.destroy }
	is_done =  business.destroy
	if is_done
	  render :json=>{:flag=> true}  
	else
	  render :json=>{:flag=> false}
	end

	end 

	private 

	def set_availability(business)
	 Date::DAYNAMES.each_with_index do |day, index|
	   # BusinessAvail.create(day_name: day ,start_hr: 9, start_min: 0, end_hr: 17, end_min: 0 , is_selected: false, business_id: business.id)
	   PractiAvail.create(day_name: day ,start_hr: 9, start_min: 0, end_hr: 17, end_min: 0 , is_selected: false, business_id: business.id)
	end
	end

	def is_business_having_all_infos(params)
	 #(params.values.include? nil) ||  (params.values.include? blank?) 
	 flag = false 
	 params.values.each do |element|
	   if element.class == ActiveSupport::HashWithIndifferentAccess
	     if (element.values.include? nil) ||  (element.values.include? "")
	       flag =true
	       break
	     else 
	       if (element.nil?) ||  (element.blank?)
	        flag = true
	        break
	       end
	     end
	   end
	 end
	 return flag      
	end

	def business_params
	 params.require(:business).permit(:id, :name , :address , :reg_name , :reg_number , :web_url , :contact_info , :online_booking , :city, :state, :pin_code, :country , :company_id,:internal_info)
	end
end
