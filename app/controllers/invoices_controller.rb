class InvoicesController < ApplicationController
  include InvoicesHelper

  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain
  before_action :find_invoice, :only => [:show, :edit, :update, :destroy, :invoice_print, :send_email_with_pdf]
  before_action :set_appointment_or_appointment_type_into_params, :only => [:create, :update]
  before_action :stop_activity

  load_and_authorize_resource param_method: :params_invoice, except: [:business_list, :patients_list, :get_invoice_item_appointmentwise, :patient_detail]
  before_filter :load_permissions

  # using only for postman to test API. Remove later  
  # skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : Invoice.per_page
    unless params[:q].blank? || params[:q].nil?
      q = params[:q]
      arr = q.split(" ")
      invoices = @company.invoices.active_invoice.avoid_del_patient.order("invoices.created_at desc").select("invoices.id , invoices.patient_id  ,  invoices.issue_date ,invoices.number ,invoices.invoice_amount").joins(:patient).where(["patients.first_name LIKE ? OR patients.last_name LIKE ? OR patients.first_name LIKE ? OR patients.last_name LIKE ?  OR invoices.number LIKE ? OR invoices.invoice_amount LIKE ? OR invoices.id LIKE ?", "%#{arr.first}%", "%#{arr.first}%", "%#{arr.last}%", "%#{arr.last}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page)
    else
      invoices = @company.invoices.active_invoice.avoid_del_patient.order("invoices.created_at desc").select("invoices.id , invoices.patient_id  ,  invoices.issue_date ,invoices.number , invoices.invoice_amount").paginate(:page => params[:page] , per_page: per_page )
    end

    result = []
    invoices.each do |invoice|
      item = {}
      item[:id] = invoice_id_format(invoice)
      item[:number] = invoice.number
      item[:patient] = invoice.patient.try(:full_name) #get_patient_name(invoice.patient)
      item[:practitioner] = invoice.user.try(:full_name_with_title) #get_practitioner_name(invoice.practitioner)
      item[:issue_date] = invoice.issue_date
      item[:invoice_amount] = '% .2f'% (invoice.invoice_amount.to_f.round(2))
      item[:outstanding_balance] = '% .2f'% (invoice.calculate_outstanding_balance.to_f.round(2))
      result << item
    end
    render :json => {invoices: result, total: invoices.count }
  end

  def new
    invoice_note = @company.invoice_setting.default_notes
    render :json => {:notes => invoice_note}
  end

  def create
    @patient = Patient.find(params_invoice[:patientid]) rescue nil
    invoice = @patient.invoices.new(params_invoice) rescue nil
    unless invoice.nil?
      if invoice.valid?
        invoice.with_lock do
          invoice.save
        end
        Invoice.public_activity_on
        invoice.create_activity :create, parameters: {total_amount: invoice.total_amount, patient_name: invoice.patient.try(:full_name), patient_id: invoice.patient.try(:id), issue_date: invoice.issue_date}

        result = {flag: true, id: "0"*(6-invoice.id.to_s.length)+ invoice.id.to_s}
        render :json => result
      else
        show_error_json(invoice.errors.messages)
      end
    else
      invoice = Invoice.new(params_invoice)
      invoice.errors.add(:patient, " can't left blank !")
      show_error_json(invoice.errors.messages)
    end
  end

  def show
    result = get_invoice_info_for_show
    render :json => result
  end

  def edit
    result = {}
    patient = @invoice.patient
    result[:patient_outstanding_balance] = '% .2f'% (patient.calculate_patient_outstanding_balance).to_f
    result[:id] = @invoice.id
    result[:invoice_number] = @invoice.number
    result[:business] = @invoice.business.try(:id)
    result[:practitioner] = @invoice.user.try(:id)
    result[:patient] = @invoice.patient.nil? ? "" : get_patient_detail_for_edit(@invoice.patient)
    result[:issue_date] = @invoice.issue_date

#   Getting associated appointment or appointment type with invoice
    if patient.appointments.length > 0 && @invoice.type_appointment == 'Appointment'
      result[:appointment] = @invoice.appointment.try(:id).to_s
    else
      result[:appointment] = @invoice.appointment_type_id.to_s
    end

    result[:type_appointment] = @invoice.type_appointment
    result[:notes] = @invoice.notes
    result[:appt_date] = @invoice.issue_date
    result[:close_date] = @invoice.calculate_outstanding_balance == 0 ? @invoice.close_date : nil
    result[:invoice_to] = @invoice.invoice_to
    result[:extra_patient_info] = @invoice.extra_patient_info
    result[:invoice_items_attributes] = []
    @invoice.invoice_items.each do |invoice_item|
      item = {}
      item[:id] = invoice_item.id
      item[:item_id] = invoice_item.item_id
      item[:concession] = invoice_item.concession
      item[:show_concession] = !(invoice_item.concession.nil?)
      item[:concession_name] = ((invoice_item.concession.nil? || invoice_item.concession.eql?("0"))  ? nil : "Discount Type: #{invoice_item.get_concession_name}")
      item[:item_type] = invoice_item.item_type
      item[:unit_price] = '% .2f'% (invoice_item.unit_price.to_f)
      item[:quantity] = invoice_item.quantity
      item[:tax] = invoice_item.tax
      item[:tax_amount] = invoice_item.tax_amount
      item[:discount] = invoice_item.discount
      item[:discount_type_percentage] = invoice_item.discount_type_percentage
      item[:total_price] = '% .2f'% (invoice_item.total_price.to_f)
      result[:invoice_items_attributes] << item
    end
    result[:total_discount] = '% .2f'% (@invoice.total_discount.to_f)
    result[:subtotal] = '% .2f'% (@invoice.subtotal.to_f)
    result[:tax] = '% .2f'% (@invoice.tax.to_f)
    result[:invoice_amount] = '% .2f'% (@invoice.invoice_amount.to_f)
    result[:outstanding_balance] = '% .2f'% (@invoice.calculate_outstanding_balance).to_f
    result[:next_invoice] = @invoice.next_invoice
    result[:prev_invoice] = @invoice.prev_invoice
    render :json => {invoice: result, appointment_list: get_appointment_list(@invoice.type_appointment)}
  end

  def update
    # Adding key destroy for deletable item
    add_destroy_key_for_invoice_item(params, @invoice) unless params[:invoice].nil?
    @invoice.update_attributes(params_invoice)
    if @invoice.valid?

      Invoice.public_activity_on
      @invoice.create_activity :update, parameters: {total_amount: @invoice.total_amount, patient_name: @invoice.patient.try(:full_name), patient_id: @invoice.patient.try(:id), issue_date: @invoice.issue_date, :other => @invoice.update_activity_log}

      result = {flag: true, id: @invoice.id}
      render :json => result
    else
      show_error_json(@invoice.errors.messages)
    end
  end

  def destroy
    @invoice.update_column(:status,false)
    invoices_payments = @invoice.invoices_payments
    if invoices_payments.present?
      invoices_payments.each do |inv_payment|
        inv_payment.update_column(:status, false)
      end
    end
    if @invoice.valid?
      Invoice.public_activity_on
      @invoice.create_activity :delete
      if $qbo_credentials.present?
        transaction = Intuit::OpustimeTransactionDelete.new(@invoice.id, @invoice.class, $token, $secret, $realm_id)
        transaction.sync_delete
      end
      result = {flag: true, id: @invoice.id}
      render :json => result
    else
      show_error_json(@invoice.errors.messages)
    end
  end

  def list_doctors
    doctors = @company.users.doctors.select("id , first_name, last_name")
    render :json => doctors
  end

  def patients_list
    patients = @company.patients.active_patient.select("id , first_name , last_name , concession_type , dob ")
    result = []
    patients.each do |patient|
      item = {}
      item[:id] = patient.id
      item[:first_name] = patient.first_name
      item[:last_name] = patient.last_name
      item[:concession_type] = patient.concession_type
      item[:dob] = (patient.dob.nil? ? patient.last_name.to_s : patient.last_name.to_s + " DOB : " + patient.dob.strftime("%d-%m-%Y"))
      result << item
    end
    render :json => result
  end

  def business_list
    businesses = @company.businesses.select("id , name")
    render :json => businesses
  end

  # Method to get appointments through practitioner and business
  def patient_detail
    unless params[:id].nil? && params[:practitioner_id].nil?
      patient = Patient.where('id=?', params['id']).select('id , invoice_to , invoice_extra_info ').first
      unless patient.nil? || !(params[:bs].present?)
        patient_appnt = patient.get_appointments_loc_and_doctor_wise(params[:bs], params[:practitioner_id])
        # patient_appnt = patient.appointments.where(:user_id=> params[:practitioner_id])  # changes it with patient.appointments
        patient_appnt_type = [] # changes with appointments type list of company
        appointments = []
        if patient_appnt.length == 0
          patient_appnt_type = @company.appointment_types.select("id , name")
        else
          patient_appnt.each do |appnt|
            item = {}
            item[:appointment_id] =appnt.try(:id)
            item[:appointment_name] = appnt.name_with_date
            item[:appointment_type_id] = appnt.appointment_type.try(:id)
            item[:appointment_type_name] = appnt.appointment_type.try(:name)
            appointments << item
          end
        end
      else
        patient_appnt_type = [] # changes with appointments type list of company
        appointments = []
      end

    else
      patient = nil
      appointments=[]
      patient_appnt_type = []
    end
    if patient.present?
      render :json => {patient: patient, appointment: appointments, appointment_type: patient_appnt_type, credit_bal: patient.calculate_patient_credit_amount.round(2)}
    else
      render :json => {patient: patient, appointment: appointments, appointment_type: patient_appnt_type, credit_bal: 0}
    end
  end

  def appointment_types_list
    appointment_types = @company.appointment_types.select("id , name")
    render :json => appointment_types
  end

  #   method to get listing of billable items and products for a specific appointment type when there is no any appointment
  def get_invoice_item_appointmentwise
    concession_id = Patient.find(params[:patient_id]).concession_type rescue nil
    cs_name = nil
    unless concession_id.nil? || concession_id.blank?
      cs_name = Concession.find(concession_id).name rescue nil
    end
    appnt_type = AppointmentType.find(params[:id])
    result = {}
    result[:billable_items] = []
    result[:products] = []

    if cs_name.nil?
      appnt_type.billable_items.each do |item|
        b_item = {}
        b_item = set_billable_hash(item) #       calling method to get other fields in hash
        if item.include_tax
          tax = which_tax(item.tax)
          unless tax.nil?
            b_item[:tax] = tax.name
            b_item[:tax_amount] = tax.amount
            b_item[:total_price] = item.price
            b_item[:unit_price] = ((item.price.to_f)/(1+(tax.amount.to_f)/100.0)).round(2)
          end
        else
          tax = which_tax(item.tax)
          unless tax.nil?
            b_item[:tax] = tax.name
            b_item[:tax_amount] = tax.amount
            b_item[:total_price] = ((item.price.to_i) + ((item.price.to_i)*(tax.amount.to_i)/100)).round(2)
          else
            b_item[:tax] = "N/A"
            b_item[:tax_amount] = 0
            b_item[:total_price] = item.price
          end
        end
        result[:billable_items] << b_item
      end

    else
      appnt_type.billable_items.try(:each) do |item|
        b_item = {}
        b_item = set_billable_hash(item) #       calling method to get hash
#       Getting concession value if available 
        billable_item_cs = BillableItemsConcession.where(["billable_item_id = ? AND concession_id = ?", item.id, concession_id]).first
        unless billable_item_cs.nil?
          b_item[:unit_price] = billable_item_cs.value
          b_item[:concession] = true
          b_item[:concession_id] = concession_id
          b_item[:concession_name] = billable_item_cs.concession.try(:name)
        end
        if b_item[:concession]
          tax = which_tax(item.tax)
          unless tax.nil?
            b_item[:tax] = tax.name
            b_item[:tax_amount] = tax.amount
            b_item[:total_price] = ((b_item[:unit_price].to_i) + ((b_item[:unit_price].to_i)*(tax.amount.to_i)/100)).round(2)
          else
            b_item[:tax] = "N/A"
            b_item[:tax_amount] = 0
            b_item[:total_price] = b_item[:unit_price]
          end
        else
          if item.include_tax
            tax = which_tax(item.tax)
            unless tax.nil?
              b_item[:tax] = tax.name
              b_item[:tax_amount] = tax.amount
              b_item[:total_price] = item.price
              b_item[:unit_price] = ((item.price.to_f)/(1+(tax.amount.to_f)/100.0)).round(2)
            end
          else
            tax = which_tax(item.tax)
            unless tax.nil?
              b_item[:tax] = tax.name
              b_item[:tax_amount] = tax.amount
              b_item[:total_price] = ((item.price.to_i) + ((item.price.to_i)*(tax.amount.to_i)/100)).round(2)
            else
              b_item[:tax] = "N/A"
              b_item[:tax_amount] = 0
              b_item[:total_price] = item.price
            end
          end
        end
        result[:billable_items] << b_item
      end
    end

    # getting selected products of appointment type
    appnt_type.products.try(:each) do |product|
      p_item = {}
      p_item[:item_id] = product.id.to_s
      p_item[:name] = product.name
      p_item[:unit_price] = product.price_exc_tax
      p_item[:discount_type_percentage] = true
      p_item[:quantity] = 1
      tax_item = TaxSetting.find(product.tax) rescue nil
      unless tax_item.nil?
        p_item[:tax] = tax_item.name
        p_item[:tax_amount] = tax_item.amount
      else
        p_item[:tax_amount] = 0
        p_item[:tax] = "N/A"
      end
      p_item[:total_price] = product.price_inc_tax
      result[:products] << p_item
    end
    render :json => result
  end

  def billable_item_list
    concession_id = Patient.find(params[:patient_id]).concession_type rescue nil
    cs_name = nil
    unless concession_id.nil?
      cs_name = Concession.find(concession_id).name rescue nil
    end
    billable_items = @company.billable_items.select("id , name, price , include_tax , tax , concession_price")
    result = []
    #   Handling both cases if patient has concession type or not
    if cs_name.nil?
      billable_items.each do |item|
        b_item = {}
        b_item = set_billable_hash(item) #       calling method to get other fields in hash
        if item.include_tax
          tax = which_tax(item.tax)
          unless tax.nil?
            b_item[:tax] = tax.name
            b_item[:tax_amount] = tax.amount
            b_item[:total_price] = item.price
            b_item[:unit_price] = ((item.price.to_f)/(1+(tax.amount.to_f)/100.0)).round(2)
          end
        else
          tax = which_tax(item.tax)
          unless tax.nil?
            b_item[:tax] = tax.name
            b_item[:tax_amount] = tax.amount
            b_item[:total_price] = ((item.price.to_i) + ((item.price.to_i)*(tax.amount.to_i)/100)).round(2)
          else
            b_item[:tax] = "N/A"
            b_item[:tax_amount] = 0
            b_item[:total_price] = item.price
          end
        end
        result << b_item
      end
    else
      billable_items.each do |item|
        b_item = {}
        b_item = set_billable_hash(item) #       calling method to get hash

        #       Getting concession value if available 
        billable_item_cs = BillableItemsConcession.where(["billable_item_id = ? AND concession_id = ?", item.id, concession_id]).first
        unless billable_item_cs.nil?
          b_item[:unit_price] = billable_item_cs.value
          b_item[:concession] = true
          b_item[:concession_id] = concession_id
          b_item[:concession_name] = billable_item_cs.concession.try(:name)
        end

        if b_item[:concession]
          tax = which_tax(item.tax)
          unless tax.nil?
            b_item[:tax] = tax.name
            b_item[:tax_amount] = tax.amount
            b_item[:total_price] = ((b_item[:unit_price].to_i) + ((b_item[:unit_price].to_i)*(tax.amount.to_i)/100)).round(2)
          else
            b_item[:tax] = "N/A"
            b_item[:tax_amount] = 0
            b_item[:total_price] = b_item[:unit_price]
          end
        else
          if item.include_tax
            tax = which_tax(item.tax)
            unless tax.nil?
              b_item[:tax] = tax.name
              b_item[:tax_amount] = tax.amount
              b_item[:total_price] = item.price
              b_item[:unit_price] = ((item.price.to_f)/(1+(tax.amount.to_f)/100.0)).round(2)
            end
          else
            tax = which_tax(item.tax)
            unless tax.nil?
              b_item[:tax] = tax.name
              b_item[:tax_amount] = tax.amount
              b_item[:total_price] = ((item.price.to_i) + ((item.price.to_i)*(tax.amount.to_i)/100)).round(2)
            else
              b_item[:tax] = "N/A"
              b_item[:tax_amount] = 0
              b_item[:total_price] = item.price
            end
          end
        end
        result << b_item
      end
    end
    render :json => result
  end

  def products_list
    # products = @company.products.active_products.where("products.stock_number > 0 ").select("id , name , price_exc_tax , price_inc_tax , tax")
    products = @company.products.active_products.select("id , name , price_exc_tax , price_inc_tax , tax")
    prod_result = []
    products.each do |product|
      result = {}
      result[:item_id] = product.id.to_s
      result[:name] = product.name
      result[:unit_price] = product.price_exc_tax
      result[:discount_type_percentage] = true
      result[:quantity] = 1
      tax_item = TaxSetting.find(product.tax) rescue nil
      unless tax_item.nil?
        result[:tax] = tax_item.name
        result[:tax_amount] = tax_item.amount
      else
        result[:tax_amount] = 0
        result[:tax] = "N/A"
      end
      result[:total_price] = product.price_inc_tax
      prod_result << result
    end
    render :json => prod_result
  end

  #   Method to generate pdf
  def invoice_print
#   Getting setting info for print from setting/document and printing
    print_setting = @company.document_and_printing
    @logo_url = print_setting.logo

#   setting missing image if logo is not available  
    if (@logo_url.to_s.include? "/assets/")
      @logo_url = @logo_url.to_s.split("/assets/")[1]
    end

    @logo_size = print_setting.logo_height
    page_size = print_setting.in_page_size
    top_margin = print_setting.in_top_margin
    @show_invoice_logo = print_setting.show_invoice_logo

    @result = get_invoice_info_for_show
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => 'pdf_name.pdf',
               :layout => '/layouts/pdf.html.erb',
               :disposition => 'inline',
               :template => "/invoices/invoice_print",
               :show_as_html => false,
               :footer => {right: '[page] of [topage]'},
               :margin => {top: top_margin.to_i},
               :page_size => page_size
      end
    end
  end
  
  def send_email_with_pdf
    unless @invoice.nil?
      #   Getting setting info for print from setting/document and printing
      print_setting = @company.document_and_printing
      @logo_url = print_setting.logo

      #   setting missing image if logo is not available
      if (@logo_url.to_s.include? "/assets/")
        @logo_url = @logo_url.to_s.split("/assets/")[1]
      end

      @logo_size = print_setting.logo_height
      page_size = print_setting.in_page_size
      top_margin = print_setting.in_top_margin
      @show_invoice_logo = print_setting.show_invoice_logo

      @result = get_invoice_info_for_show
      html = render_to_string(:action => :invoice_print, :layout => '/layouts/pdf.html.erb', :formats => [:pdf], :locals => {:@result => @result})
      pdf = WickedPdf.new.pdf_from_string(html)
      @patient_info = @invoice.patient
      @business = @patient_info.company.businesses.head.first
      # greeting_text = "Hi #{@patient_info.first_name.capitalize}"
      # comm_msg = "<p> #{greeting_text}, </p><p> Attached is your invoice from #{@business.name }  </p><p> Thank you </p><p>#{@business.name}</p>"
      flag = params[:email_to].to_s.casecmp('patient') == 0 ? true : false
      greeting_text = flag ? "Hi #{@patient_info.first_name.capitalize}" : "hello"
      comm_msg = "<p> #{greeting_text}, </p><p> Attached is your invoice from #{flag ? @business.name : @patient_info.full_name  }  </p><p> Thank you </p><p>#{@business.name}</p>"
      communication = @patient_info.communications.build(comm_time: Time.now, comm_type: "email", category: "Invoice", direction: "sent", to: @patient_info.email, from: @patient_info.company.communication_email, message: comm_msg, send_status: true, link_item: "invoice", link_id: @invoice.id)
      if communication.valid?
        communication.save
        begin
          PatientMailer.invoice_email(@patient_info, params[:email_to], @invoice, pdf).deliver_now
        rescue Exception => e
          puts e.message
        end
        result = {flag: true}
        render :json => result
      else
        show_error_json(communication.errors.messages)
      end
    else
      render :json => {:error => "Invalid invoice "}
    end
  end

  def check_security_role
    result = {}
    result[:view] = can? :index, Invoice
    result[:create] = can? :create, Invoice

    result[:modify] = can? :edit, Invoice
    result[:delete] = can? :destroy, Invoice
    result[:manage_payment] = can? :create, Payment
    render :json => result
  end

  private

  def params_invoice
    params.require(:invoice).permit(:id, :issue_date, :close_date, :appointment_type_id, :type_appointment, :invoice_to, :extra_patient_info, :notes, :total_discount, :subtotal, :tax, :invoice_amount,
                                    :invoice_items_attributes => [:id, :item_id, :item_type, :unit_price, :quantity, :discount, :tax, :total_price, :concession, :discount_type_percentage, :tax_amount, :_destroy], :appointments_invoice_attributes => [:appointment_id],
                                    :appointment_types_invoice_attributes => [:id, :appointment_type_id, :_destroy],
                                    :businesses_invoice_attributes => [:id, :business_id, :_destroy],
                                    :invoices_user_attributes => [:id, :user_id, :_destroy]

    ).tap do |whitelisted|
      whitelisted[:patientid] = params[:invoice][:patient][:id] unless params[:invoice][:patient].nil?
      if params[:invoice][:id].nil?
        whitelisted[:creater_id] = current_user.try(:id)
        whitelisted[:creater_type] = 'User'
      else
        whitelisted[:updater_id] = current_user.try(:id)
        whitelisted[:updater_type] = 'User'
      end
      whitelisted[:use_credit_balance] = params[:flag]
    end
  end

  def find_invoice
    @invoice = @company.invoices.active_invoice.find(params[:id]) rescue nil
  end

  def which_tax(id)
    TaxSetting.where(:id => id).select('name ,  amount').first rescue nil
  end

  def set_appointment_or_appointment_type_into_params
    unless params[:invoice][:patient].nil?
      patient = Patient.find(params[:invoice][:patient][:id]) rescue nil
      if patient.get_appointments_loc_and_doctor_wise(params[:invoice][:business], params[:invoice][:practitioner]).length > 0
        params[:invoice][:appointments_invoice_attributes] = {}
        params[:invoice][:appointments_invoice_attributes][:appointment_id] = params[:invoice][:appointment]
        params[:invoice][:appointment] = nil
      else
        item = {}
        item[:appointment_type_id] = params[:invoice][:appointment]
        params[:invoice][:appointment_types_invoice_attributes] = item
        params[:invoice][:appointment_type_id] = params[:invoice][:appointment]
      end
    end

    unless params[:invoice][:patient].nil?
      unless params[:invoice][:business].nil?
        item = {}
        item[:business_id]= params[:invoice][:business]
        params[:invoice][:businesses_invoice_attributes]= item
      end
    end

    unless params[:invoice][:patient].nil?
      unless params[:invoice][:practitioner].nil?
        item = {}
        item[:user_id]= params[:invoice][:practitioner]
        params[:invoice][:invoices_user_attributes]= item
      end
    end
  end

  #   Getting appointments and appointment_types for edit invoice
  def get_appointment_list(appnt)
    if appnt == "AppointmentType"
      patient_appnt_type = @company.appointment_types.select("id , name")
      return patient_appnt_type
    else
      patient = @invoice.patient
      patient_appnt = patient.appointments.where(['user_id = ? ', @invoice.user.try(:id)])
      patient_appnt_type = []
      patient_appnt.each do |appoinment|
        item = {}
        item[:appointment_id] =appoinment.id
        item[:appointment_name] = appoinment.name_with_date
        item[:appointment_type_id] = appoinment.appointment_type.try(:id)
        item[:appointment_type_name] = appoinment.appointment_type.try(:name)
        patient_appnt_type << item
      end
      return patient_appnt_type
    end
  end

  def get_invoice_info_for_show
    result = {}
    result[:id] = '0'*(6-@invoice.id.to_s.length)+ @invoice.id.to_s
    result[:created_at] = @invoice.created_at.strftime('%d %b %Y')
    result[:issue_date] = @invoice.issue_date.strftime('%d %b %Y')
    result[:offer_text] = @company.invoice_setting.offer_text
    patient = @invoice.patient
    result[:patient_outstanding_balance] = '% .2f'% @invoice.patient.try(:calculate_patient_outstanding_balance).to_f
    result[:patient_credit_balance] = '% .2f'% @invoice.patient.calculate_patient_credit_amount.to_f
    get_business_detail(@invoice.business, result, @company.invoice_setting.show_business_info) # Getting business info for invoice's show
    result[:invoice_title] = @company.invoice_setting.title
    result[:tax_invoice] = invoice_id_format(@invoice)
    result[:invoice_number] = @invoice.number
    result[:patient_id] = patient.try(:id)
    result[:patient] = patient.try(:full_name) #get_patient_name(@invoice.patientid)
    patient_address = {}
    patient_address[:address] = patient.address
    patient_address[:city] = patient.city
    patient_address[:state] = patient.state
    patient_address[:country] = patient.country
    patient_address[:postal_code] = patient.try(:postal_code)
    result[:patient_address] = patient.full_address
    result[:full_address] = patient_address
    result[:patient_dob] = patient.dob.nil? ? nil : patient.dob.to_date.strftime('%m/%d/%Y')
    result[:patient_extra_info] = patient.extra_info
    result[:email_to_patient] = patient.try(:email)
    result[:email_to_other] = patient.try(:invoice_email)
    result[:patient_extra_invoice] = patient.invoice_extra_info
    practitioner_contact_list =[]
    practi_refers_business_wise = @invoice.user.practi_refers.where(business_id: @invoice.business.id) if @invoice.business.present?
    if practi_refers_business_wise.present?
      practi_refers_business_wise.each do |practi_refer|
        item = {}
        item[:ref_type] = practi_refer.ref_type
        item[:number] = practi_refer.number
        practitioner_contact_list << item
      end
    end
    result[:practitioner_contact] = practitioner_contact_list
    result[:next_appointment_status] = @company.invoice_setting.include_next_appointment
    next_appnt = @invoice.patient.next_appointment
    unless next_appnt.nil?
      result[:next_appointment_id] = next_appnt.id
      result[:next_appointment_name] = next_appnt.name_with_date
    else
      result[:next_appointment_id] = nil
      result[:next_appointment_name] = nil
    end
    # patient_appnt = @invoice.patient.appointments.where(["user_id = ? ", @invoice.user.try(:id) ])
    result[:appt_date] = @invoice.appointment.nil? ? nil : @invoice.appointment.try(:date_and_time_without_name)
    result[:invoice_to] = @invoice.invoice_to.nil? ? patient.default_invoice_to : @invoice.invoice_to
    result[:practitioner] = @invoice.user.try(:full_name_with_title) #get_practitioner_name(@invoice.practitioner)
    result[:designation] = @invoice.user.practi_info.try(:designation).try(:humanize)
    result[:extra_patient_info] = @invoice.extra_patient_info
    invoice_items_list = []
    @invoice.invoice_items.each do |invoice_item|
      item = {}
#     getting invoice item infos - Only three columns  
      get_invoice_item_detail(invoice_item.item_id, invoice_item.item_type, item, invoice_item.concession)
      item[:unit_price] = '% .2f'% (invoice_item.unit_price.to_f)
      item[:quantity] = invoice_item.quantity
      item[:tax] = invoice_item.tax
      item[:discount] = invoice_item.discount
      item[:discount_type_percentage] = invoice_item.discount_type_percentage
      item[:total_price] = '% .2f'% (invoice_item.total_price).to_f
      invoice_items_list << item
    end
    result[:invoice_items] = invoice_items_list
    result[:total_discount] = '% .2f'% (@invoice.total_discount.to_f)
    result[:tax] = '% .2f'% (@invoice.tax.to_f)
    result[:notes] = @invoice.notes
    result[:invoice_amount] = '% .2f'% (@invoice.invoice_amount.to_f)
    result[:outstanding_balance] = '% .2f'% @invoice.calculate_outstanding_balance.to_f
    result[:payment_method] = @invoice.get_payment_detail
    result[:practitioner_signature] = @invoice.try(:user).try(:logo).try(:url).to_s
    result[:practitioner_designation] = @invoice.try(:user).try(:practi_info).try(:designation)

    refers = @invoice.try(:user).practi_refers.where(['practi_refers.business_id =? ' , @invoice.business.try(:id) ]).select('practi_refers.ref_type , practi_refers.number')
    refers_str = ''
    refers.each_with_index do |refer , index|
      refers_str = refers_str + ' , ' if index > 0
      refers_str = refers_str + refer.ref_type.to_s
      refers_str = refers_str + (refer.number.nil? ? '' : ': ' + refer.number.to_s)
    end
    result[:practitioner_desc] = refers_str
    return result
  end

  def stop_activity
    Invoice.public_activity_off
  end

end