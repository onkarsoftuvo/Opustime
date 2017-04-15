class PatientReportsController < ApplicationController
	respond_to :json
	before_filter :authorize
 	before_action :find_company_by_sub_domain , :only =>[:index , :patient_listing , :patient_list_export , :birthday_list_export , :patients_without_upcoming_appnt , :patients_without_upcoming_appnt_export , :recall_patients , :recall_patients_export , :patient_list_pdf , :recall_patients_pdf , :birthday_list_pdf , :patients_without_upcoming_appnt_pdf ]

 	def index
		authorize! :index , :patient_report
 		result = []
 		@patients = []
 		@patients = @company.patients.active_patient.where("extract(month from dob) = ?", params[:month_no].to_i).uniq if params[:month_no]
 		@patients.each do |patient|
 			item = {}
 			item[:day] = patient.dob.strftime("%dth")
 			item[:name] = patient.full_name
 			item[:patient_id] = patient.try(:id)
 			item[:email] = patient.email
			if patient.patient_contacts.present?
				item[:phone_no] = patient.patient_contacts.first.contact_no.phony_formatted(format: :international, spaces: '-')
			else
				item[:phone_no] = patient.patient_contacts.first.try(:contact_no)
			end

 			item[:address] = patient.full_address
 			result << item 
 		end
 		render :json => {month_wise_patients: result}
 	end 

 	def patient_listing
		authorize! :patient_listing, :patient_report
 		result = {}
 		result[:practitioners] = get_practitioners
 		result[:locations] = get_locations
 		result[:listing] = []
		result[:show_outstnd] = can? :outstanding_invoice, :patient_report
 		loc_params =  params[:loc].nil? ? nil : params[:loc].split(',').map{|a| a.to_i}
		doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(',').map{|a| a.to_i}

 		patients = get_patients_list(params[:start_date] , params[:end_date] , loc_params , doctor_params)
 		# @patients = get_recall_patients_only(@patients) if params[:recalls] == true || params[:recalls] == "true"
 		
 		patients_list =  []
 		if params[:outstnd_bal] == "true"
			authorize! :outstanding_invoice, :patient_report
 			patients.each do |ptn|
 				patients_list << ptn if ptn.calculate_patient_outstanding_balance > 0	
 			end
		else
			patients_list = patients
 		end

 		patients_list.each do |patient|
 			item = {}
 			item[:name] = patient.full_name
 			item[:patient_id] = patient.try(:id)
 			item[:email] = patient.email
 			# item[:phone_no] = patient.patient_contacts.first.try(:contact_no)
			if patient.patient_contacts.present?
				item[:phone_no] = patient.patient_contacts.first.contact_no.phony_formatted(format: :international, spaces: '-')
			else
				item[:phone_no] = patient.patient_contacts.first.try(:contact_no)
			end

 			item[:address] = patient.full_address
 			item[:total_invoiced] = patient.get_total_invoiced_amount(params[:start_date] , params[:end_date] , loc_params , doctor_params)
 			item[:paid_amount] = patient.total_paid_amount
 			item[:outstanding_bal] = patient.calculate_patient_outstanding_balance(params[:start_date] , params[:end_date])

 			result[:listing] << item 
 		end

 		render :json => result
 	end

 	def recall_patients
		authorize! :recall_patient , :patient_report
 		result = {}
 		result[:recalls] = @company.recall_types.select("id , name")
 		result[:practitioners] = get_practitioners
 		result[:listing] = []

 		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?
 		
 		recall_params = params[:recall_id].nil? ? nil : params[:recall_id].split(',').map{|a| a.to_i}
 		doctor_params = params[:doctor].nil? ? nil : params[:doctor].split(',').map{|a| a.to_i}
 		
 		@recalls = get_recalls_list(recall_params , start_date , end_date)

 		@recalls.each do |recall|
 			item = {}
 			item[:recall_on] = recall.recall_on_date.strftime("%d %b %Y")
 			item[:type] = recall.try(:recall_type).try(:name)
 			item[:patient_id] = recall.patient.try(:id)
 			item[:patient] = recall.patient.try(:full_name)
 			item[:practitioner] = recall.patient.last_practitioner
			if recall.patient.patient_contacts.present?
				item[:phone] = recall.patient.patient_contacts.first.contact_no.phony_formatted(format: :international, spaces: '-')
			else
				item[:phone] = recall.patient.patient_contacts.first.try(:contact_no)
			end
 			# item[:phone] = recall.patient.patient_contacts.try(:first).try(:contact_no)
 			item[:is_selected]  = recall.is_selected
 			item[:notes]  = recall.notes
 			result[:listing] << item 
 		end
 		render :json => result

 	end

 	def recall_patients_export
		authorize! :recall_patient , :patient_report
 		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?
 		
 		recall_params = params[:recall_id].nil? ? nil : params[:recall_id].split(',').map{|a| a.to_i}
 		doctor_params = params[:doctor].nil? ? nil : params[:doctor].split(',').map{|a| a.to_i}
 		
 		@recalls = get_recalls_list(recall_params , start_date , end_date)
 		respond_to do |format|
	    	format.html
	        format.csv { render text: @recalls.to_csv , status: 200 }
      	end
 	end

 	def recall_patients_pdf
		authorize! :recall_patient , :patient_report
 		@result = []
 		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?
 		
 		recall_params = params[:recall_id].nil? ? nil : params[:recall_id].split(',').map{|a| a.to_i}
 		doctor_params = params[:doctor].nil? ? nil : params[:doctor].split(',').map{|a| a.to_i}
 		
 		@recalls = get_recalls_list(recall_params , start_date , end_date)

 		@recalls.each do |recall|
 			item = {}
 			item[:recall_on] = recall.recall_on_date.strftime("%d %b %Y")
 			item[:type] = recall.try(:recall_type).try(:name)
 			item[:patient] = recall.patient.full_name
 			item[:practitioner] = recall.patient.last_practitioner
 			item[:phone] = recall.patient.patient_contacts.try(:first).try(:contact_no)
 			item[:is_selected]  = recall.is_selected
 			item[:notes]  = recall.notes
 			@result << item 
 		end
 		respond_to do |format|
	      format.html
	      format.pdf do
	        render :pdf => 'pdf_name.pdf' ,
	               :layout => "/layouts/pdf.html.erb" ,
	               :disposition => 'inline' ,
	               :template    => "/patient_reports/recall_patients_pdf",
	               :show_as_html => params[:debug].present? ,
	               :footer=> { right: '[page] of [topage]' }
	      end
	    end

 	end

 	def birthday_list_export
 		begin
			authorize! :index , :patient_report
			@patients = []
 			@patients = @company.patients.active_patient.where("extract(month from dob) = ?", params[:month_no].to_i).uniq if params[:month_no]

		    respond_to do |format|
		    	format.html
		        format.csv { render text: @patients.to_csv({} , nil , nil , false ) , status: 200 }
	        end
  		rescue Exception => e
  			render :text => e.message  	
  		end
 	end

 	def birthday_list_pdf
		authorize! :index , :patient_report
		@patients = []
		@patients = @company.patients.active_patient.where("extract(month from dob) = ?", params[:month_no].to_i).uniq if params[:month_no]
		respond_to do |format|
			format.html
			format.pdf do
				render :pdf => 'pdf_name.pdf' ,
							 :layout => "/layouts/pdf.html.erb" ,
							 :disposition => 'inline' ,
							 :template    => "/patient_reports/birthday_list_pdf",
							 :show_as_html => params[:debug].present? ,
							 :footer=> { right: '[page] of [topage]' }
			end
		end
 	end

 	def patients_without_upcoming_appnt
		authorize! :patients_without_upcoming_appnt , :patient_report
 		result = []
 		all_patients = @company.patients.active_patient
 		patient_having_future_appnts = all_patients.joins(:appointments).where(["(Date(appointments.appnt_date) > ?  AND appointments.status= ?) || (Date(appointments.appnt_date) >= ? AND appointments.appnt_time_start  > CAST(?  AS time) AND appointments.status= ?)", DateTime.now , true , DateTime.now , DateTime.now ,true ]).uniq
 		# all those patients having no future appointment
 		@patients = all_patients.active_patient - patient_having_future_appnts.active_patient
 		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?
		unless start_date.nil? && end_date.nil?
			pt_ids = @patients.map(&:id).compact
			@patients = @company.patients.active_patient.where(["patients.id IN (?) AND DATE(patients.created_at) >= ? AND DATE(patients.created_at) <= ?" , pt_ids ,  start_date , end_date])
		end

 		@patients.each do |patient|
 			item = {}
 			item[:dob] = patient.dob.nil? ? patient.dob : patient.dob.strftime("%A , %d %B %Y")
 			item[:patient] = patient.try(:id)
 			item[:name] = patient.full_name
 			item[:email] = patient.email
 			item[:phone_no] = patient.get_primary_contact
 			item[:address] = patient.full_address
 			item[:occupation] = patient.occupation
 			result << item
 		end
 		render :json => {patients: result}
 	end

 	def patients_without_upcoming_appnt_export
		authorize! :patients_without_upcoming_appnt , :patient_report
 		patient_having_future_appnts_ids = @company.patients.active_patient.joins(:appointments).where(["(Date(appointments.appnt_date) < ?  AND appointments.status= ?) || (Date(appointments.appnt_date) <= ? AND appointments.appnt_time_start  < CAST(?  AS time) AND appointments.status= ?)", DateTime.now , true , DateTime.now , DateTime.now ,true ]).map(&:id).uniq
 		@patients = @company.patients.active_patient.where(["patients.id NOT IN(?)", patient_having_future_appnts_ids ])
 		respond_to do |format|
 			format.html
	        format.csv { render text: @patients.to_csv({} , nil , nil , "none") , status: 200 }
        end
 	end


 	def patients_without_upcoming_appnt_pdf
		authorize! :patients_without_upcoming_appnt , :patient_report
 		@result = []
 		all_patients = @company.patients.active_patient
 		patient_having_future_appnts = all_patients.joins(:appointments).where(["(Date(appointments.appnt_date) < ?  AND appointments.status= ?) || (Date(appointments.appnt_date) <= ? AND appointments.appnt_time_start  < CAST(?  AS time) AND appointments.status= ?)", DateTime.now , true , DateTime.now , DateTime.now ,true ]).uniq

 		# all those patients having no future appointment 
 		@patients = all_patients.active_patient - patient_having_future_appnts.active_patient

 		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?
		unless start_date.nil? && end_date.nil?
			pt_ids = @patients.map(&:id).compact
			@patient = @company.patients.active_patient.where(["patients.id IN (?) AND DATE(created_at) >= ? AND DATE(created_at) <= ?" , pt_ids ,  start_date , end_date])
		end

 		@patients.each do |patient|
 			item = {}
 			item[:dob] = patient.dob.nil? ? patient.dob : patient.dob.strftime("%A , %d %B %Y")
 			item[:name] = patient.full_name
 			item[:email] = patient.email
 			item[:phone_no] = patient.patient_contacts.first.try(:contact_no)
 			item[:address] = patient.full_address
 			item[:occupation] = patient.occupation
 			@result << item 
 		end
 		respond_to do |format|
	      format.html
	      format.pdf do
	        render :pdf => 'pdf_name.pdf' ,
	               :layout => "/layouts/pdf.html.erb" ,
	               :disposition => 'inline' ,
	               :template    => "/patient_reports/patients_without_upcoming_appnt_pdf",
	               :show_as_html => params[:debug].present? ,
	               :footer=> { right: '[page] of [topage]' }
	      end
	    end

 	end

 	def patient_list_export
 		begin
			authorize! :patient_list , :patient_report
			@patients = []
	  	loc_params =  params[:loc].nil? ? nil : params[:loc].split(',').map{|a| a.to_i}
	    doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(',').map{|a| a.to_i}
 			@patients = get_patients_list(params[:start_date] , params[:end_date] , loc_params , doctor_params)
 			
			respond_to do |format|
				format.html
				format.csv { render text: @patients.to_csv({} , params[:start_date] , params[:end_date]) , status: 200 }
			end
  		rescue Exception => e
  			render :text => e.message
  		end
 	end

 	def patient_list_pdf
		authorize! :patient_list , :patient_report
 		@result = []
 		patients = []
  		loc_params =  params[:loc].nil? ? nil : params[:loc].split(',').map{|a| a.to_i}
    	doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(',').map{|a| a.to_i}
		patients = get_patients_list(params[:start_date] , params[:end_date] , loc_params , doctor_params)

		patients_list =  []
 		if params[:outstnd_bal] == "true"
 			patients.each do |ptn|
 				patients_list << ptn if ptn.calculate_patient_outstanding_balance > 0	
 			end
		else
			patients_list = patients
 		end

		patients_list.each do |patient|
 			item = {}
 			item[:name] = patient.full_name
 			item[:email] = patient.email
 			item[:phone_no] = patient.patient_contacts.first.try(:contact_no)
 			item[:address] = patient.full_address
 			item[:total_invoiced] = patient.get_total_invoiced_amount(params[:start_date] , params[:end_date] , loc_params , doctor_params)
 			item[:paid_amount] = patient.total_paid_amount
 			item[:outstanding_bal] = patient.calculate_patient_outstanding_balance(params[:start_date] , params[:end_date])
 			@result << item 
 		end

		respond_to do |format|
	      format.html
	      format.pdf do
	        render :pdf => 'pdf_name.pdf' ,
	               :layout => "/layouts/pdf.html.erb" ,
	               :disposition => 'inline' ,
	               :template    => "/patient_reports/patient_list_pdf",
	               :show_as_html => params[:debug].present? ,
	               :footer=> { right: '[page] of [topage]' }
	      end
	    end

 	end


 	private 

 	def get_practitioners
 		result = []
	    @company.users.doctors.each do |dc|
	      item = {}
	      item[:id] = dc.id
	      item[:name] = dc.full_name_with_title
	      result << item
	    end
	    return result 
 	end

 	def get_locations
 		result = []
 		@company.businesses.each do |business|
 			item = {}
	        item[:id] = business.id
	        item[:name] = business.name
	        result << item	
 		end
 		return result
 	end

 	def get_patients_list(start_date , end_date , business_params , doctor_params )
 		result = []
 		start_date = start_date.to_date unless start_date.nil?
 		end_date = end_date.to_date unless end_date.nil?
    	unless start_date.nil? && end_date.nil?
    		if business_params.nil? && doctor_params.nil?
    			result = @company.patients.active_patient.where(["DATE(patients.created_at) >= ? AND DATE(patients.created_at) <= ?  " , start_date , end_date])
    		elsif (!(business_params.nil?) && (doctor_params.nil?))
    			result = @company.patients.active_patient.joins(:invoices=>[:business]).where("businesses.id IN (?) " , business_params).where(["DATE(patients.created_at) >= ? AND DATE(patients.created_at) <= ?  " , start_date , end_date])
			elsif ((business_params.nil?) && (!doctor_params.nil?))
				result = @company.patients.active_patient.joins(:invoices=>[:user]).where("users.id IN (?) " , doctor_params).where(["DATE(patients.created_at) >= ? AND DATE(patients.created_at) <= ?  " , start_date , end_date])
			elsif (!(business_params.nil?) && (!doctor_params.nil?))
				result = @company.patients.active_patient.joins(:invoices=>[:business , :user]).where("users.id IN (?) AND businesses.id IN (?) " , doctor_params , business_params).where(["DATE(patients.created_at) >= ? AND DATE(patients.created_at) <= ?  " , start_date , end_date])
    		end
    	else
    		if business_params.nil? && doctor_params.nil?
    			result = @company.patients.active_patient.where(["DATE(patients.created_at) >= ?" , Date.today])
    		elsif (!(business_params.nil?) && (doctor_params.nil?))
    			result = @company.patients.active_patient.joins(:invoices=>[:business]).where("businesses.id IN (?) " , business_params)
			elsif ((business_params.nil?) && (!doctor_params.nil?))
				result = @company.patients.active_patient.joins(:invoices=>[:user]).where("users.id IN (?) " , doctor_params)
			elsif (!(business_params.nil?) && (!doctor_params.nil?))
				result = @company.patients.active_patient.joins(:invoices=>[:business , :user]).where("users.id IN (?) AND businesses.id IN (?) " , doctor_params , business_params)
    		end
    	end
 		
 	end 

 	def get_recall_patients_only(patients)
 		recall_patients = []
 		patients.each do |patient|
 			recall_patients << patient if patient.recalled?
 		end
 		return recall_patients
 	end

 	def get_recalls_list(recall_params  , start_date , end_date)
 		result = []
 		if recall_params.nil?
 			if start_date.nil? && end_date.nil?
 				result = @company.recalls.active_recall
 			else
 				result = @company.recalls.active_recall.where(["DATE(recalls.recall_on_date) >= ? AND DATE(recalls.recall_on_date) <= ?" , start_date , end_date ])
 			end
 			
 		else
 			if start_date.nil? && end_date.nil?
 				result = @company.recalls.joins(:recall_type).where(["recalls.status = ? AND  recall_types.id IN (?) " , true , recall_params ])
 			else
 				result = @company.recalls.joins(:recall_type).active_recall.where([" recalls.status = ? AND recall_types.id IN (?) AND DATE(recalls.recall_on_date) >= ? AND DATE(recalls.recall_on_date) <= ?" , true , recall_params , start_date , end_date ])
 			end
 		end	
 		return result.uniq
 	end

end
