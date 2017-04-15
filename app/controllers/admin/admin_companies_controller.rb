	class Admin::AdminCompaniesController < ApplicationController
  layout "application_admin"
	before_action :admin_authorize
	before_action :find_user, :only=>[:update]
	def new  
		puts params
	end

	def edit
		result = {}
		result = get_user_info_for_edit(@user) unless @user.nil?
		render :json => result      
	end

	def update  	
		if  params[:user].keys.include?"comming_from"
			@user.update_attributes(user_params)
	
			if @user.valid?
				render :json => {flag: true, :message => 'User was successfully updated.'} and return
			else
				render :json => {flag: false, :errors => ['phone is invalid !']} and return
			end

		else
		  	# Adding destroy- true in params for deleteable breaks
		  	max_doctor  = @company.subscription.doctors_no 
		  	avail_doctor = @company.users.doctors.count
		  	if user_params[:is_doctor]
		    	if ((avail_doctor < max_doctor) || (@user.is_doctor ))
		      	update_existing_user(params)
		    	else
		      		user = User.new
		      		user.errors.add("user", "can't be added.out of subscribed plan!")
		      		show_error_json(user.errors.messages)
		    	end
		  	else
		    	update_existing_user(params)
		  	end
		end
	rescue
		#render :json => {flag: false,:message=>'Something went wrong...!'}
		render :json => {flag: false, :errors => 'Something Wrong'} and return
	end

	def get_appointment_type_list
		apptment_types  = @company.appointment_types.select("appointment_types.id ,appointment_types.name , appointment_types.color_code")
		result = []
		apptment_types.each do |appnt|
	 		appnt_list = {}
	 		appnt_list[:appointment_type_id] = appnt.id
	 		appnt_list[:name] = appnt.name
	 	 	appnt_list[:is_selected] = false
	 	 	result << appnt_list     
		end
		render :json => result 
	end

	private

	def user_params
		params.require(:user).permit(:id , :title , :first_name , :last_name , :email , :is_doctor, :phone,:time_zone, :auth_factor, :role, :acc_active , :password , :password_confirmation , :appointment_types_users_attributes=> [:id , :appointment_type_id , :_destroy] ,
		   :practi_info_attributes=>[:id, :designation, :desc , :default_type, :notify_by , :cancel_time, :is_online, :allow_external_calendar,
		    :practi_refers_attributes =>[:id, :ref_type, :number, :business_id],
		    :practitioner_avails_attributes =>[:id,  :business_id, :business_name,
		      :days_attributes =>[:id, :day_name, :start_hr, :start_min, :end_hr, :end_min , :is_selected,
		        :practitioner_breaks_attributes =>[:id,:start_hr, :start_min, :end_hr, :end_min, :_destroy]
		      ]
		    ]
		])
	end

	def find_user
		@user = User.find(params[:id]) 
	end

	def set_params_in_format
		if current_user.id == params[:user][:id].to_i
		  params[:user].delete "role"
		end 
		unless params[:user][:practi_info_attributes].nil?
		  params[:user][:appointment_types_users_attributes] = []
		  params[:user][:practi_info_attributes][:appointment_services].each do |appnt_service|
		    if appnt_service[:is_selected]
		      item = {}
		      item[:id] = appnt_service[:id] unless appnt_service[:id].nil?
		      item[:appointment_type_id] = appnt_service[:appointment_type_id]
		      params[:user][:appointment_types_users_attributes] << item 
		    else
		      existing_record = nil
		      existing_record = AppointmentTypesUser.find_by_appointment_type_id_and_user_id(appnt_service[:appointment_type_id] , params[:user][:id] ) rescue nil  unless params[:user][:id].nil?
		      unless existing_record.nil?
		        params[:user][:appointment_types_users_attributes] << {id: existing_record.id , :_destroy=> true }                
		      end    
		    end
		  end unless params[:user][:practi_info_attributes][:appointment_services].nil?      
		end
	end

	def update_existing_user(params)
		params[:user][:practi_info_attributes] = nil  unless params[:user][:is_doctor]
		manage_deleted_params(params) unless (params[:user][:practi_info_attributes].nil? || params[:user][:practi_info_attributes][:id].nil?)
		@user.update_attributes(user_params)
		unless @user.errors.messages.count > 0
		  result = {flag: true}
		  render :json=> result 
		else
		 show_error_json(@user.errors.messages) 
		end   
	end

	def create_new_user(user_params)
		user = @company.users.new(user_params)
		if user.valid?
		  if user.save!
		  # It is adding for  choices on patient module   
		  user.create_client_filter_choice(appointment: true, treatment_note: true , invoice: true, payment: true, attached_file: true, letter: true, communication: true, recall: true) unless user.role.casecmp("bookkeeper") == 0   
		 
		  # Sending password to created user 
		  UsersWorker.perform_async(user.id)
		  result = {flag: true , id: user.id }
		  render :json=> result
		  else
		    user.errors.add(:break , "does not exist in available time")
		    show_error_json(user.errors.messages)
		  end
		else
		  show_error_json(user.errors.messages) 
		end
	end
end
