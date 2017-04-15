class SmsTemplatesController < ApplicationController
	respond_to :json
  	before_filter :authorize
  	before_action :find_company_by_sub_domain
  	before_action :find_sms_template , :only => [:edit , :update , :destroy , :get_drop_down_listing_items]

		before_filter :check_authorization , :except=> [:list , :get_drop_down_listing_items]

  	def index
  		sms_templates = @company.sms_templates.active_letter
  		result = []
  		
  		sms_templates.each do |temp|
  			item = {}
  			item[:id] = temp.id
  			item[:template_name] = temp.template_name
  			result << item
  		end

  		render :json => result
  	end

  	def create
  		sms_template = @company.sms_templates.new(sms_template_params)
  		result = {}
  		if sms_template.valid?
  			sms_template.save
  			result = {id: sms_template.id , flag: true }
  			render :json => result
  		else
  			show_error_json(sms_template.errors.messages) 
  		end
  	end

  	def edit
  		unless @sms_template.nil?
  			result = {}
  			result[:id] = @sms_template.id
  			result[:template_name] = @sms_template.template_name
  			result[:body] = @sms_template.body
  			render :json => result
  		else
  			sms_template = SmsTemplate.new()
  			sms_template.errors.add("sms_template" , "not found")
  			show_error_json(sms_template.errors.messages) 
  		end
  	end

  	def update
  		unless @sms_template.nil?
  			@sms_template.update_attributes(sms_template_params)
  			if @sms_template.valid?
	  			result = {id: @sms_template.id , flag: true }
	  			render :json => result
	  		else
	  			show_error_json(@sms_template.errors.messages) 
	  		end
  		else
  			sms_template = SmsTemplate.new()
  			sms_template.errors.add("sms_template" , "not found")
  			show_error_json(sms_template.errors.messages) 
  		end

  	end

  	def destroy
  		unless @sms_template.nil?
  			@sms_template.update_attributes(status: false)
  			if @sms_template.valid?
	  			result = {flag: true }
	  			render :json => result
	  		else
	  			show_error_json(@sms_template.errors.messages) 
	  		end
  		else
  			sms_template = SmsTemplate.new()
  			sms_template.errors.add("sms_template" , "not found")
  			show_error_json(sms_template.errors.messages) 
  		end

  	end

    def list
      sms_templates = @company.sms_templates.active_letter
      result = []
      
      sms_templates.each do |temp|
        item = {}
        item[:id] = temp.id
        item[:template_name] = temp.template_name
        item[:body] = temp.body
        result << item
      end

      render :json => result
    end


    def get_drop_down_listing_items

      result =  {}
      result[:practitioners] = []
      result[:locations] = []
      result[:contacts] = []

      @tabs = @sms_template.addition_tabs
      result[:tabs] = @tabs
      @tabs.each_pair do |key , val|
        result[:practitioners] = get_all_doctors if key.casecmp("practitioner") == 0 && val == true
        result[:locations] = get_all_locations if key.casecmp("business") == 0 && val == true
        result[:contacts] = get_all_contacts if key.casecmp("contact") == 0 && val == true
      end
      render :json => result

    end

  	private

  	def sms_template_params
  		params.require(:sms_template).permit(:id, :template_name, :body).tap do |whitelisted|
	    	whitelisted[:addition_tabs] = set_aditional_tabs_info(params)       
	    end
		end

		def check_authorization
			authorize! :manage, SmsTemplate
		end

  	#  setting tabs selection which one are using in content   
   	def set_aditional_tabs_info(params)
   		item  = {practitioner: false , business: false , contact: false}
     	content = params[:sms_template][:body]
    	content  = "" if params[:sms_template][:body].nil?
     	if content.include?"{{Contact."
       		item[:contact] = true
     	end
     	if content.include?"{{Business."
       		item[:business] = true
     	end
     	if content.include?"{{Practitioner."
       		item[:practitioner] = true
     	end
     	return item
   	end

   	def find_sms_template
   		@sms_template = @company.sms_templates.active_letter.find_by_id(params[:id])
   	end 

    def get_all_doctors
      doctors = []
      @company.users.doctors.select("id , title , first_name , last_name").each do |doct|
        item = {}
        item[:id] = doct.id
        item[:name] = doct.full_name
        doctors << item
      end

      return doctors
    end

    def get_all_locations
      loc = []
      @company.businesses.select("id , name").each do |bs|
        item = {}
        item[:id] = bs.id
        item[:name] = bs.name
        loc << item
      end
      return loc
    end

    def get_all_contacts
      contacts = []
      records = @company.contacts.where(contact_type: "Doctor" , status: true).select("id , title , first_name , last_name")
      records.each do |contact|
        item = {}
        item[:id] = contact.id
        item[:name] = contact.full_name
        contacts << item
      end

      return contacts
    end

end
