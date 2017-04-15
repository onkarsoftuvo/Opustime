class AppointmentTypeController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :new  , :create , :products_list , :billable_items_list]
  before_action :find_appointment_type , :only=> [:edit , :update , :destroy]
  before_action :set_params_in_format , :only=> [:create , :update]

  load_and_authorize_resource  param_method: :appointment_type_params , except: [:index  , :products_list , :billable_items_list]
  before_filter :load_permissions
  
  
  
  def index
    begin
      appointments = @company.appointment_types.select("id ,name , color_code , duration_time ")
      result = []
      appointments.each do |appnt_type|
        item = {}
        item[:id] = appnt_type.id
        item[:name] = appnt_type.name
        item[:color_code] = appnt_type.color_code
        item[:duration_time] = appnt_type.duration_time.to_i
        result << item 
      end
      render :json=>  result
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end
  end
  
  def new 
    begin
      appointment_type = @company.appointment_types.new
      result = {}
      result[:name] = appointment_type.name
      result[:description] = appointment_type.description
      result[:category] = appointment_type.category
      result[:duration_time] = appointment_type.duration_time
      result[:default_note_template] = appointment_type.template_note.try(:id)
      result[:color_code] = appointment_type.color_code
      result[:confirm_email] = appointment_type.confirm_email
      result[:send_reminder] = appointment_type.send_reminder
      result[:allow_online] = appointment_type.allow_online
      result[:related_product] = []
      result[:billable_item] = []
      result[:doctors] = []
      
      # Getting all practitioner lists 
      doctors = @company.users.select("id, first_name , last_name").doctors
      doctors.each do |doctor|
        item = {}
        item[:user_id] = doctor.id
        item[:name] = doctor.full_name
        item[:is_selected] = false
        result[:doctors] << item
      end
      result[:doctors] = result[:doctors].sort_by { |hsh| hsh[:user_id] }
      
      render :json=> { appointment_type:result } 
      
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end 
  end
   
  def create
    begin  
      appointment_type = @company.appointment_types.build(appointment_type_params)
      if appointment_type.valid?
        # appointment_type.prefer_practi = params[:doctors]
        appointment_type.save
  
  #     To Assign practitioners for a appointment type
        params[:doctors].each do |doctor|
          AppointmentTypesUser.create(appointment_type_id: appointment_type.id , user_id: doctor["id"], is_selected: doctor["is_selected"] , first_name: doctor["first_name"] , last_name: doctor[:last_name] ) if doctor["is_selected"]
        end unless params[:doctors].nil?
         
        result = {flag: true , id: appointment_type.id}
        render :json=> result
      else
        show_error_json(appointment_type.errors.messages)  
      end
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end
    
  end
  
  def edit
    begin 
      result = {}
      result[:id] = @appointment_type.id
      result[:name] = @appointment_type.name
      result[:description] = @appointment_type.description
      result[:category] = @appointment_type.category
      result[:duration_time] = @appointment_type.duration_time
      result[:default_note_template] = @appointment_type.template_note.try(:id)
      result[:color_code] = @appointment_type.color_code
      result[:confirm_email] = @appointment_type.confirm_email
      result[:send_reminder] = @appointment_type.send_reminder
      result[:allow_online] = @appointment_type.allow_online
      
      # Getting billable item list
      result[:billable_item] = []
      appnt_bills =  AppointmentTypesBillableItem.where(["appointment_type_id =?" , @appointment_type.id])
      appnt_bills.each do |record|
        item = {}
        item[:id]= record.try(:id)
        item[:billable_item_id]= record.billable_item.try(:id)
        item[:name]= record.billable_item.try(:name)
        result[:billable_item] << item    
      end
      
      # Getting products list 
      result[:related_product] = []
      appnt_products = AppointmentTypesProduct.joins(:product).where(["appointment_type_id =? AND products.status = ?" , @appointment_type.id , true])
      
      appnt_products.each do |record|
        item = {}
        item[:id]= record.try(:id)
        item[:product_id]= record.product.try(:id)
        item[:name]= record.product.try(:name)
        result[:related_product] << item    
      end 
      
      # Getting selected practitioners  
      result[:doctors] = []
      appnt_practitioners = AppointmentTypesUser.joins(:user).where(["users.acc_active = ? AND appointment_type_id =?" , true , @appointment_type.id])
      selected_practitioners = []
      appnt_practitioners.each do |appnt_doctor|
        item = {}
        item[:id] = appnt_doctor[:id]
        item[:user_id] = appnt_doctor[:user_id]
        selected_practitioners << appnt_doctor[:user_id]
        item[:name] = appnt_doctor.user.try(:full_name)
        item[:is_selected]= true 
        result[:doctors] << item   
      end
      
      if selected_practitioners.count ==0
        doctors = @appointment_type.company.users.select("id, first_name , last_name").doctors    
      else
        doctors = @appointment_type.company.users.select("id, first_name , last_name").where(["id NOT IN (?)", selected_practitioners]).doctors
      end
      
      doctors.each do |doctor|
        item = {}
        item[:user_id] = doctor.id
        selected_practitioners << doctor.id
        item[:name] = doctor.try(:full_name)
        item[:is_selected]= false
        result[:doctors] << item 
      end
      result[:doctors] = result[:doctors].sort_by { |hsh| hsh[:user_id] }
      
      
      render :json=>{appointment_type: result} 
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end    
  end
  
  def update
    begin 
      @appointment_type.update_attributes(appointment_type_params)
      if @appointment_type.valid?
        render :json=> {flag: status , :id=> @appointment_type.id }
      else
        show_error_json(@appointment_type.errors.messages)
      end
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end
  end 
  
  def destroy
    begin
      appointment_type  = AppointmentType.find(params[:id])
      appointment_type.destroy
      render :json=> {flag:  true}
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end
  end
  
  def products_list
    begin
      products_list = @company.products.select("id, name").active_products
      result = []
      products_list.each do |product|
        item = {}
        item[:product_id] = product.id
        item[:name] = product.name
        result << item 
      end
      render :json=> result 
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end    
  end
  
  def billable_items_list
    begin 
      billable_items = @company.billable_items.select("id, name")
      result=  []
      billable_items.each do |billable_item|
        item = {}
        item[:billable_item_id] =  billable_item.id
        item[:name] =  billable_item.name
        result << item 
      end
      render :json=> result
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end 
  end
  
  
  private 
  
  def appointment_type_params
    params.require(:appointment_type).permit(:id , :name,  :description, :category , :duration_time , :color_code, :reminder ,  :confirm_email, :send_reminder , :allow_online , 
     :appointment_types_users_attributes=> [:id , :user_id , :_destroy],
     :appointment_types_template_note_attributes=>[:id,:template_note_id,:_destroy],
     :appointment_types_billable_items_attributes => [:id , :billable_item_id , :_destroy],
     :appointment_types_products_attributes => [:id , :product_id , :_destroy] )
  end
  
  def find_appointment_type
    @appointment_type  = AppointmentType.select("id , name , description , category , duration_time , color_code , confirm_email , send_reminder , allow_online, company_id").find(params[:id]) rescue nil 
  end
  
  def set_params_in_format
    # managing billable_items 
    params[:appointment_type][:appointment_types_billable_items_attributes] = []
    params[:appointment_type][:appointment_types_products_attributes]  = []
    used_billable_item = []
    used_products = []
    unless params[:appointment_type][:billable_item].nil?
      params[:appointment_type][:billable_item].each do |billable_item|
        item = {}
        item[:id] = billable_item[:id] unless billable_item[:id].nil? 
        item[:billable_item_id] = billable_item[:billable_item_id]
        used_billable_item << billable_item[:billable_item_id]
        params[:appointment_type][:appointment_types_billable_items_attributes] << item     
      end
    end  
    # Adding destroy key for deleted billable items
    unless  params[:appointment_type][:id].nil?
      appnt_type = AppointmentType.find(params[:appointment_type][:id]) rescue nil 
      if used_billable_item.count > 0
        deleted_billable_items = AppointmentTypesBillableItem.where(["billable_item_id NOT IN (?) AND appointment_type_id=? " , used_billable_item , appnt_type.id]).select("id")   
      else 
        deleted_billable_items = AppointmentTypesBillableItem.where(["appointment_type_id =? " , appnt_type.id]).select("id")
      end      

      deleted_billable_items.each do |del_appnt|
        params[:appointment_type][:appointment_types_billable_items_attributes] << {:id=> del_appnt.id , :_destroy=> true }  
      end
    end
    
    # managing products
    unless params[:appointment_type][:related_product].nil?
      params[:appointment_type][:related_product].each do |product|
        item = {}
        item[:id] = product[:id] unless product[:id].nil? 
        item[:product_id] = product[:product_id]
        used_products << product[:product_id]
        params[:appointment_type][:appointment_types_products_attributes] << item     
      end
    end
    # Adding destroy key for deleted products
    unless  params[:appointment_type][:id].nil?
      appnt_type = AppointmentType.find(params[:appointment_type][:id]) rescue nil
      deleted_products = [] 
      if used_products.count > 0
        deleted_products = AppointmentTypesProduct.where(["product_id NOT IN (?) AND appointment_type_id = ?" , used_products , appnt_type.id]).select("id") unless appnt_type.nil?        
      else
        deleted_products = AppointmentTypesProduct.where(["appointment_type_id =? " , appnt_type.id]).select("id")
      end
      
      deleted_products.each do |del_product|
        params[:appointment_type][:appointment_types_products_attributes] << {:id=> del_product.id , :_destroy=> true }  
      end
    end
    
    # manage practitioners
    params[:appointment_type][:appointment_types_users_attributes] = []
    params[:appointment_type][:doctors].each do |doctor|
      if doctor[:is_selected]== true
        item = {}
        item[:id] = doctor[:id] unless doctor[:id].nil?
        item[:user_id] = doctor[:user_id]   
        params[:appointment_type][:appointment_types_users_attributes] << item    
      else
        existing_record = nil
        existing_record = AppointmentTypesUser.find_by_appointment_type_id_and_user_id(params[:appointment_type][:id] , doctor[:user_id] ) rescue nil  unless params[:appointment_type][:id].nil?
        unless existing_record.nil?
          params[:appointment_type][:appointment_types_users_attributes] << {id: existing_record.id , :_destroy=> true }                
        end   
      end
    end  
     
     #manage template_note
    params[:appointment_type][:appointment_types_template_note_attributes] = {}
    item = {}
    at_id = params[:appointment_type][:default_note_template].to_i 
    
    if at_id > 0
        if params[:action] == "update"
          unless at_id == @appointment_type.template_note.try(:id)
            item[:template_note_id] = at_id
            params[:appointment_type][:appointment_types_template_note_attributes] = item
          else
            item[:id] = @appointment_type.appointment_types_template_note.id
            item[:template_note_id] = at_id
            params[:appointment_type][:appointment_types_template_note_attributes] = item  
         end
         else
           item[:template_note_id] = at_id
           params[:appointment_type][:appointment_types_template_note_attributes] = item
        end
     else
        if params[:action] == "update"
          unless @appointment_type.template_note.nil?
            record = AppointmentTypesTemplateNote.where(["appointment_type_id =? AND template_note_id=? ",@appointment_type.id, @appointment_type.template_note.id]).first
            item[:id] = record.try(:id)
            item[:_destroy] = true
            params[:appointment_type][:appointment_types_template_note_attributes] = item  
          end
          
        end
     end
    
  end
  
#  To remove prefer practitioners who were selected but not now 
  def set_prefer_practi(doctor_list , appnt_type_id)
    user_ids_in_appnt =   AppointmentTypesUser.where(["appointment_type_id=? ",appnt_type_id]).map(&:user_id)
    removable_appnt_user_ids = user_ids_in_appnt -  doctor_list
    removable_appnt_user_ids.each do |appnt_user_id|
      appt_usr = AppointmentTypesUser.find_by_appointment_type_id_and_user_id(appnt_type_id , appnt_user_id)
      appt_usr.destroy unless appt_usr.nil?
    end
  end
  
  def set_billable_items(params)
    billable_items = []
    unless params[:appointment_type][:billable_item].nil?
      params[:appointment_type][:billable_item].each do |billable_item|
        item = {}
        item[:id] = billable_item[:id]
        item[:name] = billable_item[:name]
        billable_items << item     
      end
    end 
    return billable_items  
  end
  
  def set_related_product(params)
    related_products = []
    unless params[:appointment_type][:related_product].nil?
      params[:appointment_type][:related_product].each do |related_product|
        item = {}
        item[:id] = related_product[:id]
        item[:name] = related_product[:name]
        related_products << item     
      end
    end 
    return related_products
  end
  
end
