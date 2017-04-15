class ImportsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only => [:index , :create , :update]

  before_action :set_format , :only => [:create]
  before_action :set_import , :only => [:show , :update , :destroy]

  load_and_authorize_resource  param_method: :import_params
  before_filter :load_permissions

  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  
  def index
    result = []
    imports = @company.imports.order("created_at desc")
    imports.each do |record|
      item = {}
      item[:id] = record.id
      item[:file_name] = record.doc_file_name
      item[:created_at] = record.created_at.strftime("%d %b %Y, %H:%M%p")
      item[:import_type] = record.import_type
      item[:obj_count] = record.imported_obj_ids.try(:length)
      item[:status] = record.status
      item[:show_btn] = record.show_delete
      result << item
    end

    render :json=> result
  end

  def show
    result = []
    spreadsheet = Roo::Spreadsheet.open(@import.doc.url, csv_options: {encoding: Encoding::ISO_8859_1} )
    total_records = (spreadsheet.last_row)-1
    header = spreadsheet.row(1) #.map{|k| k.split(" ").join("_")}
    header.each_with_index do |title , index|
      item = {}
      item[:your_field] = title
      which_index = title.nil? ? title : (find_index_as_per_title(title.split(" ").join("_") , params[:obj_type] ))
      item[:matched_column] = which_index 
      item[:sample] = title.nil? ? title : (get_sample_values_from_doc(title , spreadsheet ))
      result << item
    end

    render :json=> {record: result , sample_len: (total_records > 5 ? 5 : total_records) }
  end

  # GET /imports/new
  def new
    @import = Import.new
  end

  # GET /imports/1/edit
  def edit

  end

  def create
    result = {flag: true}
    if is_valid_file(params[:file])
      # custom_file = create_csv_file(params[:file])  
      if params[:id].present?
        import = @company.imports.find(params[:id])
        import.update_attributes(doc: params[:file] , :doc_content_type=> "text/csv") unless params[:file].nil?
        result = {id: import.id , flag: true }
        render :json => result
      else
        import = @company.imports.new(import_params) 
        import.doc_content_type = "text/csv"  
        if import.save
          result = {id: import.id , flag: true }
          render :json => result
        else
          show_error_json(import.errors.messages)
        end
      end

    else
      import = Import.new
      import.errors.add(:doc_type , "is invalid")
      show_error_json(import.errors.messages)
    end

  end

  def update
    spreadsheet = Roo::Spreadsheet.open(@import.doc.url, csv_options: {encoding: Encoding::ISO_8859_1} )
    header = spreadsheet.row(1)
    flag =  true
    data =  params[:import][:data]
    count = 0
    new_obj_ids = []
    col_names = get_col_names_for_spefic_model(params[:import][:obj_type])
    (2..spreadsheet.last_row).each do |row_no|
      
      # stop to enter blank row of sheet
      next if spreadsheet.row(row_no).compact.length <= 0 

      actual_columns = {}
      actual_columns[:patient_contacts_attributes] =[] if params[:import][:obj_type].eql?('patient')
      actual_columns[:contact_nos_attributes] =[] if params[:import][:obj_type].eql?('contact')
      data.each_with_index do |sel_val , dt_index|
        if %w(mobile_number home_number work_number fax_number other_number).include?("#{col_names[sel_val.to_i]}")
          actual_columns[:patient_contacts_attributes] << { contact_type:  "#{col_names[sel_val.to_i]}".split('_')[0].to_sym , :contact_no => spreadsheet.row(row_no)[dt_index]} if params[:import][:obj_type].eql?('patient')
          actual_columns[:contact_nos_attributes] << { :contact_type => "#{col_names[sel_val.to_i]}".split('_')[0].to_sym ,  contact_number:  spreadsheet.row(row_no)[dt_index]} if params[:import][:obj_type].eql?('contact')
        else
          actual_columns["#{col_names[sel_val.to_i]}"] = spreadsheet.row(row_no)[dt_index] unless sel_val == "none"
        end
      end
      begin
        if params[:import][:obj_type] == 'patient'
          obj = @company.patients.new(actual_columns)
        elsif params[:import][:obj_type] == 'contact'
          obj = @company.contacts.new(actual_columns)
        elsif params[:import][:obj_type] == 'product'
          if !(actual_columns['tax_name'].nil?) && !(actual_columns['tax_amount'].nil?)
            tax_setting = @company.tax_settings.where(['name LIKE (?) AND amount = ?' , "%#{actual_columns['tax_name']}%" , actual_columns['tax_amount'] ]).first
            actual_columns.delete'tax_name'
            actual_columns.delete'tax_amount'
            actual_columns['tax'] = tax_setting.try(:id)
          end
          obj = @company.products.new(actual_columns)
        elsif params[:import][:obj_type] == 'billableItem'
          if !(actual_columns['tax_name'].nil?) && !(actual_columns['tax_amount'].nil?)
            tax_setting = @company.tax_settings.where(['name LIKE (?) AND amount = ?' , "%#{actual_columns['tax_name']}%" , actual_columns['tax_amount'] ]).first
            actual_columns.delete'tax_name'
            actual_columns.delete'tax_amount'
            actual_columns['tax'] = tax_setting.try(:id)
          end
          obj = @company.billable_items.new(actual_columns)
        end
        
        if obj.save(validate: false)
          count = count + 1
          new_obj_ids << obj.id
        else
          flag = false
          break
        end
      rescue Exception => e
        flag = false
        new_obj_ids.each do |pt_id|
          Patient.find(pt_id).destroy if params[:import][:obj_type] == "patient"
          Contact.find(pt_id).destroy if params[:import][:obj_type] == "contact"
          Product.find(pt_id).destroy if params[:import][:obj_type] == "product"
          BillableItem.find(pt_id).destroy if params[:import][:obj_type] == "billableItem"
        end
        new_obj_ids = []
      end
    end
    if flag
      @import.update_columns(status: IMPORT_STATUS[2] , imported_obj_ids: new_obj_ids)
    else
      @import.update_columns(status: IMPORT_STATUS[1])
    end  

    render :json => { flag: true }
    
  end

  def destroy
    @import.delete_associated_records
    # ImportWorker.perform_async(@import.id)
    @import.destroy

    render :json=> {flag: true}
  end

  def get_model_names
    result = {}
    if params[:obj] == "patient"
      result[:attributes_fields] = patient_columns
    elsif params[:obj] == "contact"
      result[:attributes_fields] = contact_columns
    elsif params[:obj] == "product"
      result[:attributes_fields] = product_columns
    elsif params[:obj] == "billableItem"
      result[:attributes_fields] = billableItem_columns
    end
    render :json=> result
  end

  def records

  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_import
      @import = Import.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def import_params
      params.require(:import).permit(:import_type, :status, :show_delete ,:doc).tap do |whitelisted|
        whitelisted[:user_id] = current_user.id
      end
    end

    def set_format
      unless params.nil?
        params[:import] = {}
        params[:import][:status] = IMPORT_STATUS[0]
        params[:import][:show_delete] = true
        params[:import][:doc] = params[:file]
        params[:import][:import_type] = params[:data]
      end
    end

    # path where a constant file csv is kept

    def export_file_path
      file_path  = Rails.root.to_s + "/public/export.csv"
    end

    def is_valid_file(file)
      flag = false
      file_ext = File.extname(file.original_filename)
      if (file_ext == ".csv" && !(record_no(file).nil?)) 
        flag = true
      end
      return flag
    end

    def record_no(file)
      spreadsheet = Roo::Spreadsheet.open(file.path , csv_options: {encoding: Encoding::ISO_8859_1}  )
      no = spreadsheet.last_row rescue nil
      return no
    end

    def only_patient_columns
      column_names = Patient.column_names
      column_names = column_names - %W(created_at company_id updated_at relationship id qbo_id referral_id profile_pic_file_name profile_pic_content_type profile_pic_file_size profile_pic_updated_at )
      return column_names + %w(mobile_number home_number work_number fax_number other_number)
    end

    def patient_columns
      column_names = only_patient_columns
      arr = []
      column_names.each_with_index do |column,  index|
        item = {}
        item[:attr_name] = column.split('_').join(' ')
        item[:value] = index
        arr << item 
      end
      return arr 
    end

    def only_contact_columns
      column_names = Contact.column_names
      column_names = column_names - %w(created_at company_id updated_at id)
      return column_names +  %w(mobile_number home_number work_number fax_number other_number)
    end

    def contact_columns
      column_names = only_contact_columns
      arr = []
      column_names.each_with_index do |column,  index|
        item = {}
        item[:attr_name] = column.split("_").join(" ")
        item[:value] = index
        arr << item 
      end
      return arr 
    end

    def only_product_columns
      column_names = Product.column_names
      column_names = column_names - ["created_at" , "company_id", "updated_at" , "id" , "xero_code" , 'price_inc_tax' , 'price_exc_tax' , 'tax' ]
      return column_names + ['tax_name' , 'tax_amount']
    end

    def product_columns
      column_names = only_product_columns
      arr = []
      column_names.each_with_index do |column,  index|
        item = {}
        item[:attr_name] = column.split("_").join(" ")
        item[:value] = index
        arr << item 
      end
      return arr
    end

    def only_billableItem_columns
      column_names = BillableItem.column_names
      column_names = column_names - %w(created_at company_id updated_at id xero_code qbo_id income_account_ref expense_account_ref )
      return column_names + ['tax_name' , 'tax_amount']
    end

    def billableItem_columns
      column_names = only_billableItem_columns
      arr = []
      column_names.each_with_index do |column,  index|
        item = {}
        item[:attr_name] = column.split("_").join(" ")
        item[:value] = index
        arr << item 
      end
      return arr 
    end


    def doc_content(file)
      spreadsheet = Roo::Spreadsheet.open(file.path, csv_options: {encoding: Encoding::ISO_8859_1} )
    end

    def find_index_as_per_title(title , obj="patient")
      column_names = only_patient_columns if obj=="patient"
      column_names = only_contact_columns if obj=="contact"
      column_names = only_product_columns if obj=="product"
      column_names = only_billableItem_columns if obj=="billableItem"
      title = column_name_format(title) 
      index = column_names.find_index(title)
      return (index.nil? ?  index : index.to_s)
    end

    def get_sample_values_from_doc(title , spreadsheet )
      count = 1 
      arr = {}
      column_index = spreadsheet.row(1).find_index(title)
      (2..(spreadsheet.last_row)).each do |row_no|
          arr["sample_#{row_no-1}"] = spreadsheet.row(row_no)[column_index]  
        if count == 5
          break
        else
          count = count + 1
        end
      end  
      
      return arr 
    end

    def patient_extra_fields
       ["patient id" , "Patient ID" , "id" ,"phone mobile", "phone home", "phone work", "phone fax", "phone other" ,  "medicare", "referral type", "referral type subcategory" , "referring doctor" ,"created at", "updated at", "last appointment" ,  "last practitioner seen", "last business visited", "account credit", "medical alert", "archived", "concession type"]
    end

    def contact_extra_fields
      ["Contact id" , "Contact ID" , "id" ,"phone mobile", "phone home", "phone work", "phone fax", "phone other"]
    end

    def product_extra_fields
      ["Product id" , "Product ID" , "id" , "tax name", "tax amount(%)" ]
    end

    def billableItem_extra_fields
      ["BillableItem id" , "BillableItem ID" , "id" , "tax amount(%)" , "cost price"]
    end

    def extra_attributes_from_file(obj_type, data , header , obj_extra_fields, actual_col)
      col_names = {}
      data.each_with_index do |dt , index|
        col_name = header[index]
        unless obj_extra_fields.include? col_name
          unless dt == "none"    
            col_names["#{col_name.split(" ").map{|k| k.downcase}.join(" ")}"] = actual_col[dt.to_i]    
          end
        end
      end

      return col_names
    end

    def column_name_format(col_name)
      col_name = col_name.split(" ").map{|k| k.downcase}.join("_")
    end

    def get_col_names_for_spefic_model(obj_type)
      col_name = []
      if obj_type == "patient"
        col_name = only_patient_columns  
      elsif obj_type == "contact"
        col_name = only_contact_columns  
      elsif obj_type == "product"
        col_name = only_product_columns
      elsif obj_type == "billableItem"
        col_name = only_billableItem_columns  
      end
      return col_name
    end

end
