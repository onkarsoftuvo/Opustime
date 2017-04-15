class ReferralTypePatientsController < ApplicationController
	respond_to :json
	before_filter :authorize
 	before_action :find_company_by_sub_domain
	before_action :check_authorization , except: [:chart_data]
 	
 	def index
 		result = {}
 		result[:doctor] = all_practitioners
 		result[:referral] = all_referral_types
 		result[:list] = []
		
		start_date = params[:st_date].to_date unless params[:st_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?

		referral_ids = params[:referral_id].nil? ? [] : params[:referral_id].split(",").map{|a| a.to_i}
		referral_sources = get_referral_names(referral_ids)
 		patients = patient_counting_referral_type(start_date , end_date , referral_sources )
 		
 		patients.each do |patient|
 			item = {}
 			item[:patient_id] = patient.try(:id)
 			item[:name] = patient.full_name
			if patient.patient_contacts.present?
				item[:number] = patient.patient_contacts.first.contact_no.phony_formatted(format: :international, spaces: '-')
			else
				item[:number] = patient.patient_contacts.first.try(:contact_no)
			end
 			# item[:number] = patient.patient_contacts.try(:first).try(:contact_no)
 			item[:date] = patient.created_at.strftime("%d %b %Y , %H:%M%p")
 			item[:referral_source] = patient.referral_type
 			item[:referral_type] = patient.referral_type_subcategory
 			item[:extra_info] = patient.extra_info
 			result[:list] << item
 		end
 		render :json=> result

 	end

 	def chart_data
 		result = {}
		result[:series] = []
		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?
		
		all_referral_types.each do |ref_type|
			item = {}
			obj_name = ref_type.referral_source
            amount = patient_counting_referral_type(start_date , end_date , ref_type.referral_source).length
            item[:name] = obj_name.to_s + " (#{amount})" 
            item[:data] = amount
            result[:series] << item 	
		end
 			
 		render :json => result
 	end

 	def export

 		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?

		referral_ids = params[:referral_id].nil? ? [] : params[:referral_id].split(",").map{|a| a.to_i}
		referral_sources = get_referral_names(referral_ids) 
 		
 		patients = patient_counting_referral_type(start_date , end_date , referral_sources)	
 		
 		respond_to do |format|
	    	format.html
	        format.csv { render text: patients.to_csv({} , nil , nil , "refer") , status: 200 }
      	end
 		
 	end

 	def generate_pdf
 		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?

		referral_ids = params[:referral_id].nil? ? [] : params[:referral_id].split(",").map{|a| a.to_i}
		referral_sources = get_referral_names(referral_ids) 
 		patients = patient_counting_referral_type(start_date , end_date , referral_sources )
 		@result = []
 		patients.each do |patient|
 			item = {}
 			item[:name] = patient.full_name
 			item[:number] = patient.patient_contacts.try(:first).try(:contact_no)
 			item[:date] = patient.created_at.strftime("%d %b %Y , %H:%M%p")
 			item[:referral_source] = patient.referral_type
 			item[:referral_type] = patient.referral_type_subcategory
 			item[:extra_info] = patient.extra_info
 			@result << item
 		end
 		respond_to do |format|
	      format.html
	      format.pdf do
	        render :pdf => "pdf_name.pdf" , 
	               :layout => '/layouts/pdf.html.erb' ,
	               :disposition => 'inline' ,
	               :template    => "/referral_type_patients/generate_pdf.pdf.erb",
	               :show_as_html => params[:debug].present? ,
	               :footer=> { right: '[page] of [topage]' }
	      end 
	    end

 	end

 	private

	def check_authorization
		authorize! :refer , :refer_patient
	end

 	def all_practitioners
		if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
			doctors = @company.users.doctors.where(['users.id = ?' , current_user.id])
		else
			doctors = @company.users.doctors
		end

 		result = []
 		doctors.each do |doctor|
 			item = {}
 			item[:id] = doctor.id
 			item[:name] = doctor.full_name_with_title
 			result << item
 		end
 		return result
 	end

 	def all_referral_types
 		@company.referral_types.select("id , referral_source")
 	end

 	def patient_counting_referral_type(start_date=nil , end_date=nil , source_name)
 		result = []
		if start_date.nil? && end_date.nil?
			result = @company.patients.active_patient.where([" patients.referral_type IN (?) " , source_name])
		else
			result = @company.patients.active_patient.where(["DATE(patients.created_at) >= ? AND DATE(patients.created_at) <= ? AND patients.referral_type IN (?) " , start_date , end_date , source_name])
		end
		return result
 	end


 	def get_referral_names(referral_ids) 
 		names = []
 		if referral_ids.length > 0 
 			names = @company.referral_types.where(["referral_types.id IN (?)" ,referral_ids ]).map(&:referral_source)
		else
			names = @company.referral_types.map(&:referral_source) 			
 		end
 		return names
 	end
end
