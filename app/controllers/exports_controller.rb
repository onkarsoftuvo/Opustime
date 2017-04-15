class ExportsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :create , :download , :lists , :get_treatment_notes ]

  before_action :set_export, only: [:show, :edit, :update, :destroy]
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  before_filter :check_access_permission , :only=> [:create]

  def index

    result = Export.all
    render :json => result

  end

  def create
    start_date = params[:export][:st_date].to_date
    end_date = params[:export][:end_date].to_date
    if params[:export][:obj_type].to_i > 0 
      params[:temp_id] = params[:export][:obj_type].to_i
      params[:export][:obj_type] = "Treatment Notes"
    end

    begin 
      export =  insert_content_into_file(params[:export][:obj_type] , start_date , end_date)
      if export.save
        File.open(export_file_path, 'w') {|file| file.truncate(0) }
        result = {flag: true }
        render :json => result  
      else
        show_error_json(export.errors.messages)
      end

    rescue Exception => e
      render :json => {:error=> e.message }  
    end 
    
  end

  # deleting export record 

  def destroy
    @export.destroy
    render :json=> {flag: true}
  end

  # downloading csv file for a particular export record 

  def download
    result = {}
    export = @company.exports.find_by_id(params[:id])
    doc = export.doc
    # send_file export.doc.url.split("?")[0] ,:type => export.doc_content_type , :x_sendfile => true
    unless export.doc_content_type.eql?('text/csv')
      send_data export.doc.url ,
                :filename => export.doc_file_name ,
                :type => export.doc_content_type ,
                :disposition => 'attachment'
    else
      data = open(export.doc.url)
      send_data data.read, :x_sendfile => true, :type => 'text/csv; charset=iso-8859-1; header=present',
          :disposition => "attachment; filename=#{export}.csv"
    end
  end

  def lists
    result = {}
    result[:export_listing] = get_export_listing
    render :json => result
  end

  def get_treatment_notes
    result = []
    notes = @company.template_notes.joins(:treatment_notes).uniq
    notes.each do |note|
      item = {}
      item[:id] = note.id
      item[:name] = note.name
      result << item
    end
    render :json=> result 

  end

  def check_access_permission
    unless params['export']['obj_type'].nil?
      case params['export']['obj_type']
        when 'Products'
          authorize! :export , Product
        when 'invoice'
          authorize! :export , Invoice
        when 'Payments'
          authorize! :export , Payment
        when 'Expenses'
          authorize! :export , Expense
        else
          authorize! :export , :other
      end
    end
    return

  end

  def check_access_permission_export
    flag = nil
    unless params['obj_type'].nil?
      case params['obj_type']
        when 'Products'
          flag = can? :export , Product
        when 'invoice'
          flag = can? :export , Invoice
        when 'Payments'
          flag = can? :export , Payment
        when 'Expenses'
          flag = can? :export , Expense
        else
          flag = can? :export , :other
      end
    end
    render :json => {flag: flag}

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_export
      @export = Export.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def export_params
      params.require(:export).permit(:ex_type, :ex_date_range, :company_id)
    end

    def get_export_listing
      result = []
      @company.exports.order("created_at desc").each do |record|
        item = {}
        item[:id] = record.id
        item[:export_type] = record.ex_type
        item[:date_range] = record.ex_date_range.gsub("-" , " to ")
        flag = record.ex_type.include?("file")
        item[:file_name] =  record.generate_custom_name(flag)
        item[:created_at] = record.created_at.strftime("%d %b %Y, %H:%M%p")
        result  << item
      end
      return result
    end

    def insert_content_into_file(obj_type , start_date , end_date)
      begin

        obj_name = ""
        records = []
        case obj_type
          when "invoice"
            column_name = ["invoice_id","issue_date" , "patient_full_name",
             "patient_first_name" , "patient_last_name", "practitioner",
             "sub_total_amount", "tax_amount", "discount","Invoice_amount" ,
              "notes" , "status","date_closed","created_by" , "appointment_id", 
               "business" , "invoice_to" , "extra_patient_info","patient_id",
               "patient_date_of_birth","outstanding_balance"]
            
            obj_name = "invoice"

            records = @company.invoices.active_invoice.where(["DATE(invoices.issue_date) >= ? AND DATE(invoices.issue_date) <= ? AND invoices.status =? ", start_date , end_date ,  true])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                # csv << ([]<< column_name.join(" "))
                 csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                 csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << record.id
                  data << record.issue_date
                  patient = record.patient
                  data << patient.full_name
                  data << patient.first_name
                  data << patient.last_name
                  data << record.user.try(:full_name_with_title)
                  data << record.subtotal 
                  data << record.tax
                  data << record.total_discount
                  data << record.invoice_amount
                  data << record.notes
                  data << (record.calculate_outstanding_balance > 0 ? "open" : "paid")
                  data << (record.close_date.nil? ? "" : record.close_date)
                  data << current_user.full_name 
                  data << (record.appointment.nil? ? "" : record.appointment.id)
                  data << record.business.try(:name)
                  data << record.invoice_to
                  data << record.extra_patient_info
                  data << ("0"*(6-patient.id.to_s.length)+ patient.id.to_s)
                  data << (patient.dob.nil? ? "" : patient.dob.strftime("%d-%m-%Y"))
                  data << record.calculate_outstanding_balance

                  # csv << ([] << data.join(" "))
                  csv << data
                end
              end
            end
          when "Payments"
            column_name =["payment_id", "payment_date","patient"]
            column_name = column_name + @company.get_payment_types_names.map{|k| k.gsub(" ","_")}
            column_name = column_name + ["amount", "created_at" , "updated_at","notes"]
            obj_name = "payment"
            records = @company.payments.active_payment.where(["DATE(payments.payment_date) >= ? AND DATE(payments.payment_date) <= ? AND payments.status =? ", start_date , end_date ,  true])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << formatted_obj_id(record)
                  data << record.payment_date.strftime("%d/%m/%Y")
                  data << record.patient.full_name
                  @company.payment_types.pluck("id , name").each do |p_type|
                    data << get_paid_amount_for_a_specific_p_type(record , p_type)  
                  end
                  data << record.get_paid_amount
                  data << record.created_at.strftime("%d/%m/%Yat%H:%M%p")
                  data << record.updated_at.strftime("%d/%m/%Yat%H:%M%p")
                  data << record.notes
                  # csv << ([] << data.join(" ")) 
                  csv << data
                end  
              end
            end
          when "Appointments"
            column_name = ["id", "start_time", "end_time", "practitioner", 
              "practitioner_id", "patient(s)", "patient_id(s)", "appointment_type", 
              "appointment_note", "business", "did_not_arrive", "patient_arrived", 
              "sms_reminder_sent", "email_reminder_sent", "cancellation_time", 
              "cancellation_reason", "cancellation_note", "created_at" , 
              "treatment_notes_status", "invoice_id", "appointment_category", 
              "source", "maximum_number_of_patients"]
            obj_name = "appointment"  
            records = @company.appointments.where(["appointments.status = ? AND  DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ? ", true , start_date , end_date ]).uniq
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                # csv << ([]<< column_name.join(" "))
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                # csv << ([]<< column_name.join(" "))
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << (record.appnt_time_start.strftime("%H:%M%p"))
                  data << (record.appnt_time_end.strftime("%H:%M%p"))
                  data << (record.user.full_name_with_title)
                  data << (formatted_obj_id(record.user))
                  data << (record.patient.full_name)
                  data << (formatted_obj_id(record.patient))
                  data << (record.appointment_type.try(:name))
                  data << (record.notes)
                  data << (record.business.try(:name))
                  data << record.patient_arrive.nil?
                  data << (record.patient_arrive.nil? ? "No" : "yes")
                  data << false  # later change it with sms reminder 
                  data << false  # later change it with email reminder 
                  data << (record.cancellation_time.nil? ? "" : record.cancellation_time.strftime("%d/%m/%Yat%H:%M%p"))
                  data << record.reason.to_s
                  data << (record.cancellation_notes.to_s)
                  data << record.created_at.strftime("%d/%m/%Yat%H:%M%p")
                  data << (record.treatment_notes.length > 0 ? "Yes" : "No")
                  data << (record.invoices.length > 0 ? (formatted_obj_id(record.invoices.first)) : "")
                  data << (" ") #appointment_category change it later
                  data << (" ") # source change it later 
                  data << 1 # maximum_number_of_patients -  change it later 
                  csv << data 
                end
              end
            end
          when "Patients"
            column_name =["id", "title", "first_name", "last_name", "dob",
             "gender", "email", "phone_mobile", "phone_home", "phone_work", "phone_fax",
              "phone_other", "address", "city", "state", "postal_code", "country", 
              "occupation", "emergency_contact", "medicare", "referral_type",
               "referral_type_subcategory", "extra_information", "referring_doctor", 
               "reference_number", "created_at" , "updated_at", "last_appointment", 
               "birth_month", "last_practitioner_seen", "last_business_visited", 
               "account_credit", "medical_alert", "archived", "notes", "reminder_type", 
               "invoice_to", "invoice_email", "invoice_extra_info", "concession_type", 
               "sms_marketing"]  
            obj_name = "patient"  
            records = @company.patients.active_patient.where(["DATE(patients.created_at) >= ? AND DATE(patients.created_at) <= ?", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                # csv << ([]<< column_name.join(" "))
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                # csv << ([]<< column_name.join(" "))
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = [] 
                  data << (formatted_obj_id(record)) 
                  data << (record.title.to_s)
                  data << (record.first_name.to_s)
                  data << (record.last_name.nil? ? " " : record.last_name)
                  data << (record.dob.nil? ? " " :record.dob.strftime("%d/%m/%Y"))
                  data << (record.gender.to_s)
                  data << (record.email.nil? ? " " : record.email)
                  data << (record.get_mobile_no_type_wise("mobile"))
                  data << (record.get_mobile_no_type_wise("home"))
                  data << (record.get_mobile_no_type_wise("work"))
                  data << (record.get_mobile_no_type_wise("fax"))
                  data << (record.get_mobile_no_type_wise("other"))
                  data << (record.address.to_s)
                  data << (record.city.to_s)
                  data << (record.state.to_s)
                  data << (record.postal_code.to_s)
                  data << (record.country.to_s)
                  data << (record.occupation.to_s)
                  data << (record.emergency_contact.to_s) 
                  data << (record.medicare_number.to_s) 
                  data << (record.referral_type.to_s) 
                  data << (record.referral_type_subcategory.to_s) 
                  data << (record.extra_info.to_s) 
                  data << (record.contact.nil? ? " " : record.contact.full_name.to_s)
                  data << (record.reference_number.to_s) 
                  data << (record.created_at.strftime("%d/%m/%Yat%H:%M%p"))
                  data << (record.updated_at.strftime("%d/%m/%Yat%H:%M%p"))
                  data << (record.last_appointment.nil? ? " " : record.last_appointment.appnt_date.strftime("%d/%m/%Yat%H:%M%p"))
                  data << (record.dob.nil? ? " " : record.dob.strftime("%B")) 
                  data << (record.last_appointment.nil? ? " " : record.last_appointment.user.full_name.to_s)
                  data << (record.last_appointment.nil? ? " " : record.last_appointment.business.name.to_s)
                  data << (record.calculate_patient_credit_amount.to_s)
                  data << (record.medical_alerts.length)
                  data << (record.status == "archive")
                  data << (record.notes.to_s)
                  data << (record.reminder_type.to_s)
                  data << (record.invoice_to.to_s)
                  data << (record.invoice_email.to_s)
                  data << (record.invoice_extra_info.to_s)
                  data << (record.concession.nil? ? " " : record.concession.name.to_s)
                  data << (record.sms_marketing)
                  csv << data 
                end
              end 
            end 
          when "Products"
            column_name =["id", "item_code", "name", "serial_number", "tax_name",
             "tax_amount(%)", "stock_level", "price(ex_tax)", "cost_price", 
             "supplier_name", "created_at" , "updated_at","note"]
            obj_name = "product" 
            records = @company.products.active_products.where(["DATE(products.created_at) >= ? AND DATE(products.created_at) <= ? ", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << record.item_code.to_s
                  data << record.name.to_s
                  data << record.serial_no.to_s
                  data << record.tax_setting.try(:name)
                  data << record.tax_setting.try(:amount)
                  data << (record.stock_number)
                  data << record.price_exc_tax
                  data << record.cost_price
                  data << record.supplier
                  data << record.created_at.strftime("%d-%m-%Y at %H:%M%p")
                  data << record.updated_at.strftime("%d-%m-%Y at %H:%M%p")
                  data << record.note.to_s
                  csv << data 
                end
              end
            end
          when "Expenses"
            column_name =["id", "expence_date", "vendor", "category", "notes", 
              "sub_total", "tax", "total", "created_by", "business"]
            obj_name = "expense" 
            records = @company.expenses.where(["DATE(expenses.expense_date) >= ? AND DATE(expenses.expense_date) <= ? ", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << (record.expense_date.nil? ? " " : record.expense_date.strftime("%d-%m-%Y at %H:%M%p"))
                  data << record.vendor.to_s
                  data << record.category.to_s
                  data << record.note.to_s
                  data << (record.total_expense - record.tax_amount)
                  data << record.tax_amount
                  data << record.total_expense
                  data << record.created_at.strftime("%d-%m-%Y at %H:%M%p")
                  data << record.business_info
                  csv << data   
                end
              end
            end  

          when "Contacts"  
            column_name =["id", "title", "first_name", "last_name", "preferred_name", 
              "company_name", "email", "phone_mobile", "phone_home", "phone_work", 
              "phone_fax", "phone_other", "address", "city",
               "state", "postal_code", "country", "occupation",  "notes", 
               "provider_number", "created_at", "updated_at"]
            obj_name = "contact"
            records = @company.contacts.active_contact.where(["DATE(contacts.created_at) >= ? AND DATE(contacts.created_at) <= ? ", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << record.title.to_s
                  data << record.first_name.to_s
                  data << record.last_name.to_s
                  data << record.preffered_name.to_s
                  data << record.company_name.to_s
                  data << record.email.to_s
                  data << (record.get_mobile_no_type_wise("mobile"))
                  data << (record.get_mobile_no_type_wise("home"))
                  data << (record.get_mobile_no_type_wise("work"))
                  data << (record.get_mobile_no_type_wise("fax"))
                  data << (record.get_mobile_no_type_wise("other"))
                  data << record.address.to_s
                  data << record.city.to_s
                  data << record.state.to_s
                  data << record.post_code
                  data << record.country.to_s
                  data << record.occupation.to_s
                  data << record.notes.to_s
                  data << record.provider_number.to_s
                  data << record.created_at.strftime("%d-%m-%Y at %H:%M%p")
                  data << record.updated_at.strftime("%d-%m-%Y at %H:%M%p")
                  csv << data  
                end
              end
            end
          when "Letters"     
            column_name =["id", "description", "patient", "practitioner", "business", 
              "contents", "created_at", "updated_at"]
            obj_name = "letter"
            records = @company.letters.active_letter.where(["DATE(letters.created_at) >= ? AND DATE(letters.created_at) <= ? ", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << record.description.to_s
                  data << record.patient.try(:full_name)
                  data << record.get_doctor_info
                  data << record.get_business_info
                  data << record.content.try(:html_safe)
                  data << record.created_at.strftime("%d-%m-%Y at %H:%M%p")
                  data << record.updated_at.strftime("%d-%m-%Y at %H:%M%p")
                  csv << data 
                end
              end
            end
          when "InvoiceItems"
            column_name =["id", "item_code", "name", "type", "unit_price", 
              "quantity", "tax_id", "tax_name", "tax_amount", "net_price", "total", 
              "item_id", "concession_type_id", "concession_type_name", 
              "discount_percentage", "discount_amount", "invoice_id", "invoice_date" , 
              "patient_id", "patient", "practitioner_id", "practitioner",
               "extra_patient_info", "patient_date_of_birth", "business"]
            obj_name = "invoiceItem"
            records = @company.invoice_items.where(["DATE(invoice_items.created_at) >= ? AND DATE(invoice_items.created_at) <= ? ", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << record.get_item_code
                  data << record.get_item_name
                  data << record.item_type.to_s
                  data << record.unit_price
                  data << record.quantity
                  data << record.get_tax_id(@company , record.tax)
                  data << record.tax
                  data << record.tax_amount
                  data << record.unit_price
                  data << record.total_price
                  data << record.item_id
                  data << record.concession.to_s
                  data << record.get_concession_name
                  data << record.discount.to_s
                  data << record.discount_amount
                  data << formatted_obj_id(record.invoice)
                  data << record.invoice.try(:issue_date)
                  patient = record.invoice.patient 
                  data << formatted_obj_id(patient)
                  data << (patient.full_name)
                  data << formatted_obj_id(record.invoice.user)
                  data << (record.invoice.user.full_name_with_title)
                  data << patient.invoice_extra_info
                  data << patient.dob.to_s
                  data << record.invoice.try(:business).try(:name)
                  csv << data 
                end
              end
            end 
          when "StockAdjustments"  
            column_name =["adjustment_id", "date_created", "quantity",
             "adjustment_type", "comment", "product_id", "product_item_code", 
             "product_name", "user"]
            obj_name = "productStock"
            records = @company.product_stocks.where(["DATE(product_stocks.created_at) >= ? AND DATE(product_stocks.created_at) <= ? ", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << record.created_at.strftime("%d-%m-%Y at %H:%M%p")
                  data << record.quantity
                  data << record.stock_type
                  data << record.note
                  data << (formatted_obj_id(record.product)) 
                  data << (record.product.item_code).to_s 
                  data << (record.product.name).to_s 
                  data << record.stock_adjusted_by
                  csv << data 
                end 
              end 
            end

          when "BillableItems"  
            column_name = ["name", "item_type", "item_code", "tax_name", "tax_amount(%)", "price", "cost_price"]
            obj_name = "billableitem"
            records = @company.billable_items.where(["DATE(billable_items.created_at) >= ? AND DATE(billable_items.created_at) <= ? ", start_date , end_date ])
            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << record.try(:name)
                  data << (record.item_type ? "Service":"Other")
                  data << record.item_code
                  data << record.tax_setting.try(:name)
                  data << record.tax_setting.try(:amount)
                  data << record.get_price
                  data << record.price
                  csv << data 
                end
              end
            end 
          when "Treatment Notes"
            
            column_name =["treatment_note_id", "title", "patient", "patient_id", 
              "pratitioner", "draft", "text", "created_at", "updated_at", "appointment", 
              "appointment_id"]
            obj_name = "treatmentNote"
            if params[:temp_id].present?
              records = @company.treatment_notes.joins(:template_note).where(["DATE(treatment_notes.created_at) >= ? AND DATE(treatment_notes.created_at) <= ? AND template_notes.id = ? ", start_date , end_date , params[:temp_id] ])
            else
              records = @company.treatment_notes.where(["DATE(treatment_notes.created_at) >= ? AND DATE(treatment_notes.created_at) <= ? ", start_date , end_date ])
            end

            if records.length == 0 
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
              end
            else
              file_csv = CSV.open(export_file_path, "wb") do |csv|
                csv << (column_name.map{|k| k.split("_").join(" ") })
                records.each do |record|
                  data = []
                  data << (formatted_obj_id(record))
                  data << record.title
                  data << record.patient.try(:full_name)
                  data << record.patient.try(:id)
                  data << record.practitioner_name
                  data << !(record.save_final)
                  data << record.paper_format
                  data << record.created_at
                  data << record.updated_at
                  data << record.appointment.try(:name_with_date) 
                  data << (record.appointment.nil? ? " " : (formatted_obj_id(record.appointment)))

                  csv << data 

                end
              end
            end
          when "PatientsAttachments"
            records = @company.file_attachments.where(['DATE(file_attachments.created_at) >= ? AND DATE(file_attachments.created_at) <= ?', start_date , end_date])
            input_filenames = []
            
            zipfile_name = File.join(Rails.root,"public","export.zip")
            my_zip = Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
              records.each do |filename|
                f_name = filename.avatar.original_filename

                zipfile.add(f_name , filename.avatar.url) rescue nil
              end
            end
            # Zip:sort_entries = true
          
        end
        
        unless obj_type == "PatientsAttachments"
          file = File.open(export_file_path , 'a')
          doc_type = obj_name  + "(#{records.length})"
          date_range = start_date.to_date.strftime("%d/%m/%Y").to_s + "-" + end_date.to_date.strftime("%d/%m/%Y").to_s
          export = @company.exports.new(:ex_type => doc_type , :ex_date_range => date_range , :doc => file )
          export.doc_content_type = "text/csv"  
        else
          file = File.open(zipfile_name , 'a')
          doc_type = "file_attachments"+ "(#{records.length})"
          date_range = start_date.to_date.strftime("%d/%m/%Y").to_s + "-" + end_date.to_date.strftime("%d/%m/%Y").to_s
          export = @company.exports.new(:ex_type => doc_type , :ex_date_range => date_range , :doc => file )
          export.doc_content_type = "application/zip"
        end
        
        return export
      
      rescue Exception => e
        puts "Error 's msg : #{e.message}"
      end 

    end

    def export_file_path
      file_path  = Rails.root.to_s + "/public/export.csv"
    end

    def formatted_obj_id(obj)
      ("0"*(6-obj.id.to_s.length)+ obj.id.to_s)    
    end

    def get_paid_amount_for_a_specific_p_type(payment , p_type)  
      payment.payment_types_payments.find_by_payment_type_id(p_type.first).try(:amount).to_s
    end
    
end
