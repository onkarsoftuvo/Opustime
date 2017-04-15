class PaymentsController < ApplicationController
  include PaymentsHelper

  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain, :only => [:index, :create, :new, :payment_sources_list, :avail_payment_types, :patient_outstanding_invoices, :payment_print]
  before_action :find_payment, :only => [:show, :edit, :update, :destroy, :payment_print]
  before_action :set_params_in_format, :only => [:create, :update]
  before_action :stop_activity

  load_and_authorize_resource param_method: :payment_params, :except => [:patient_outstanding_invoices]
  before_filter :load_permissions

  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : Payment.per_page
    unless params[:q].blank? || params[:q].nil?
      q = params[:q]
      arr = q.split(" ")
      payments = @company.payments.active_payment.joins(:patient).where(["payments.id = ? OR payments.notes LIKE ? OR patients.first_name LIKE ? OR patients.last_name LIKE ? OR patients.first_name LIKE ? OR patients.last_name LIKE ?", "#{params[:q]}", "%#{params[:q]}%", "%#{arr.first}%", "%#{arr.first}%", "%#{arr.last}%", "%#{arr.last}%"]).order("payments.created_at desc").select("payments.id , payments.payment_date , payments.patient_id").paginate(:page => params[:page] ,  per_page: per_page)
    else
      payments = @company.payments.active_payment.order("payments.created_at desc").select("payments.id , payments.payment_date , payments.patient_id").paginate(:page => params[:page] , per_page: per_page )
    end

    result = []
    payments.each do |payment|
      item = {}
      item[:id] = id_format(payment)
      item[:patient] = get_patient_info(payment, "payment")
      item[:payment_date] = payment.payment_date
      item[:paid_amount] =  '% .2f'% (payment.get_paid_amount).to_f
      item[:payment_type] = payment.pay_type
      result << item
    end


    render :json => { payment: result , total: payments.count }
  end

  def new
    result = {}
    unless params[:invoice_id].nil?
      invoice = Invoice.find(params[:invoice_id])
      result[:business] = invoice.business.try(:id)
      result[:patient] = get_patient_info(invoice, "invoice")
      result[:payment_date] = nil
      result[:payment_hr] = nil
      result[:payment_min] = nil
      result[:previous_payment_types_used] = [] # invoice.patient.payments.last.payment_types_payments.map(&:payment_type_id).first unless invoice.patient.payments.length == 0
      result[:payment_sources]=[]
      result[:notes] = nil
      result[:invoices] = []
    else
      result[:business] = nil
      result[:patient] = nil
      result[:payment_date] = nil
      result[:payment_hr] = nil
      result[:payment_min] = nil
      result[:payment_sources]=[]
      result[:notes] = nil
      result[:invoices] = []
    end

    render :json => {payment: result}
  end

  def create
    patient = Patient.find(params[:payment][:patient][:id]) rescue nil
    unless patient.nil?
      payment = patient.payments.new(payment_params)
      if payment.valid?
        payment.with_lock do
          payment.save
        end

        Payment.public_activity_on
        payment.create_activity :create, parameters: {total_amount: payment.deposited_amount_of_invoice, patient_name: payment.patient.try(:full_name), patient_id: payment.patient.try(:id), payment_methods: payment.payment_ways.join(","), used_invoices: payment.attached_invoices_ids}

        render :json => {flag: true, :id => payment.id}
      else
        show_error_json(payment.errors.messages)
      end
    else
      payment = Payment.new()
      payment.valid?
      show_error_json(payment.errors.messages)
    end
  end

  def show
    result = {}
    result[:id] = id_format(@payment)
    result[:payment_date] = @payment.payment_date
    result[:patient] = get_patient_info(@payment, "payment")
    result[:notes] = @payment.notes
    result[:payment_history] = @payment.get_paid_payments_and_total
    result[:invoices_history] = @payment.get_invoices_list_applied_payment
    result[:next] = @payment.next_payment
    result[:prev] = @payment.prev_payment
    render :json => {payment: result}
  end

  def edit
    result = {}
    result[:id] = @payment.id
    result[:business] = @payment.business.try(:id)
    result[:patient] = get_patient_info(@payment, "payment")
    result[:payment_date] = @payment.payment_date.strftime("%Y-%m-%d")
    result[:payment_hr] = @payment.payment_date.strftime("%H").to_i
    result[:payment_min] = @payment.payment_date.strftime("%M").to_i
    result[:payment_types_payments_attributes] = @payment.get_payment_sources # get_payment_sources(@payment)
    result[:invoices_payments_attributes] = [] #@payment.get_list_invoices(@payment.patient)
    result[:notes] = @payment.notes
    render :json => {payment: result}
  end

  def update
    before_paid = @payment.deposited_amount_of_invoice

    @payment.update_attributes(payment_params)
    if @payment.valid?

      Payment.public_activity_on
      @payment.create_activity :update, parameters: {total_amount: @payment.deposited_amount_of_invoice, patient_name: @payment.patient.try(:full_name), patient_id: @payment.patient.try(:id), payment_methods: @payment.payment_ways.join(","), used_invoices: @payment.attached_invoices_ids, :other => @payment.update_activity_logs(before_paid)}

      render :json => {flag: true, :id => @payment.id}
    else
      show_error_json(@payment.errors.messages)
    end

  end

  def destroy
    @payment.update_attributes(:status=> false)
    if @payment.valid?
      Payment.public_activity_on
      @payment.create_activity :delete
      if $qbo_credentials.present?
        transaction = Intuit::OpustimeTransactionDelete.new(@payment.id, @payment.class, $token, $secret, $realm_id)
        transaction.sync_delete
      end
      render :json => {flag: true, :id => @payment.id}
    else
      show_error_json(@payment.errors.messages)
    end
  end

  def patient_outstanding_invoices
#   Getting those invoices for which some amount has been deposited
    patient = which_patient(params[:id]) rescue nil
    payment =patient.payments.where(id: params[:payment_id]).first
    result = {}
    unless patient.nil?
      previous_invoices_ids = []
      invoice_result = []
      unless payment.nil?
        previous_paid_payment_for_invoices = payment.invoices_payments.active_invoices_payments.order("invoices_payments.created_at desc") #InvoicesPayment.where(:payment_id => self.id)
        previous_paid_payment_for_invoices.each do |invoice_payment|
          unless invoice_payment.amount == 0 && invoice_payment.credit_amount == 0
            invoice = invoice_payment.invoice
            item = {}
            item[:id] = invoice_payment.id
            item[:invoice_id] = id_format(invoice)
            item[:invoice_number] = invoice.number
            previous_invoices_ids << invoice.id
            item[:issue_date] = invoice.issue_date
            item[:practitioner] = invoice.user.try(:full_name) #practitioner_name(invoice.practitioner)
            item[:invoice_total] =  '% .2f'% (invoice.invoice_amount.to_f)
            item[:amount_outstanding] = '% .2f'% ((deposited_amount_of_invoice(invoice.id, payment.id) == 0 ? invoice.calculate_outstanding_balance(payment.id).to_f : (invoice.calculate_outstanding_balance(payment.id).to_f + deposited_amount_of_invoice(invoice.id, payment.id).to_f)).to_f.round(2))
            item[:credit_amount] =  '% .2f'% (invoice_payment.credit_amount.to_f.round(2))
            item[:amount] = '% .2f'% ((deposited_amount_of_invoice(invoice.id, payment.id)).to_f.round(2)- invoice_payment.credit_amount.to_f.round(2))
            item[:amount_remaining] = '% .2f'% (item[:amount_outstanding].to_f - (item[:amount].to_f + item[:credit_amount].to_f))
            invoice_result << item
          end
        end
      end
      #   Getting all new invoices for this patient
      if previous_invoices_ids.length > 0
        new_invoices = patient.invoices.active_invoice.where("invoices.id NOT IN (?)", previous_invoices_ids).order("invoices.created_at desc").select("invoices.id , invoices.issue_date,invoices.number, invoices.invoice_amount")
      else
        new_invoices = patient.invoices.active_invoice.order("invoices.created_at desc").select("invoices.id , invoices.issue_date , invoices.invoice_amount,invoices.number,invoices.outstanding_balance")
      end

      new_invoices.each do |invoice|
        unless invoice.calculate_outstanding_balance == 0
          item = {}
          item[:invoice_id] = id_format(invoice)
          item[:invoice_number] = invoice.number
          item[:issue_date] = invoice.issue_date
          item[:practitioner] = invoice.user.try(:full_name) # practitioner_name(invoice.practitioner)
          item[:invoice_total] = '% .2f'% (invoice.invoice_amount.to_f)
          item[:amount_outstanding] = '% .2f'% ((invoice.calculate_outstanding_balance).to_f.round(2))
          item[:credit_amount] = 0
          item[:amount] = 0 #deposited_amount_of_invoice(invoice.id)
          item[:amount_remaining] = '% .2f'% (item[:amount_outstanding].to_f)
          invoice_result << item
        end
      end
      result[:rest_invoices_list] = invoice_result
      result[:patient_outstanding] = '% .2f'% (patient.calculate_patient_outstanding_balance.to_f.round(2))
      result[:credit_account] = '% .2f'% (payment.nil? ? patient.calculate_patient_credit_amount.to_f : (patient.calculate_patient_credit_amount.to_f - (payment.get_paid_amount - payment.deposited_amount_of_invoice))).to_f.round(2)
    end
#   Getting which one last payment type was used previously  
    last_used_payment_type = patient.payments.last.payment_types_payments.map(&:payment_type_id).first unless patient.payments.length == 0

#   Getting Cash payment id used in initial payment  
#     cash_payment_type_id = @company.payment_types.where(:name => "Cash").first.id if last_used_payment_type.nil?
    cash_payment_type_id = @company.payment_types.first.id if last_used_payment_type.nil?

    render :json => {:rest_invoices => result, :default_payment_type_id => last_used_payment_type.nil? ? cash_payment_type_id : last_used_payment_type}
  end

  def avail_payment_types
    payment_types = @company.payment_types.select("id , name")
    result = []
    payment_types.each do |pay_type|
      item = {}
      item[:payment_type_id] = pay_type.id
      item[:name] = pay_type.name
      result << item
    end
    render :json => result
  end

  #   To view the payment in pdf format
  def payment_print
    @result = {}

    #   Getting setting info for print from setting/document and printing
    print_setting = @company.document_and_printing
    @logo_url = print_setting.logo

    @result[:id] = id_format(@payment)
    business = @payment.business rescue nil
    @result[:business_name] = business.name
    @result[:business_address] = business.full_address
    @result[:reg_name] = business.reg_name
    @result[:reg_number] = business.reg_number
    @result[:web_url] = business.web_url
    @result[:payment_date] = @payment.payment_date
    @result[:patient] = @payment.patient.full_name
    # @result[:notes] = @payment.notes
    @result[:payment_history] = @payment.get_paid_payments_and_total
    @result[:invoices_history] = []
    @payment.invoices_payments.each do |invoice_payment|
      invoice = invoice_payment.invoice
      item = {}
      item[:invoice_id] = id_format(invoice)
      item[:invoice_items] = invoice.get_items_info.join(",")
      item[:invoice_date] = invoice_payment.created_at.strftime("%d %b %Y")
      item[:practitioner] = invoice.user.try(:full_name) #invoice.practitioner_name
      item[:payment_types] = @payment.payment_ways
      item[:invoice_tax] = invoice.tax
      item[:invoice_total] = invoice.invoice_amount
      item[:payment_applied_to_invoice] = invoice_payment.amount + invoice_payment.credit_amount
      @result[:invoices_history] << item
    end
    @result[:total_applied_payments] = @payment.deposited_amount_of_invoice
    # render :json => @result
    respond_to do |format|
      # format.html
      format.pdf do
        render :pdf => "pdf_name.pdf",
               :layout => '/layouts/pdf.html.erb',
               :disposition => 'inline',
               :template => "/payments/payment_print",
               :show_as_html => params[:debug].present?
      end
    end
  end

  def check_security_role
    result = {}
    result[:view] = can? :index, Payment
    result[:create] = can? :create, Payment
    result[:modify] = can? :update, Payment
    result[:delete] = can? :destroy, Payment

    render :json => result
  end

  private

  def payment_params
    params.require(:payment).permit(:id, :payment_date, :notes,
                                    :payment_types_payments_attributes => [:id, :amount, :payment_type_id],
                                    :invoices_payments_attributes => [:id, :amount, :credit_amount, :invoice_id],
                                    :businesses_payment_attributes => [:id, :business_id, :_destroy]
    ).tap do |whitelisted|
      whitelisted[:businessid] = params[:payment][:business].nil? ? nil : params[:payment][:business]
      whitelisted[:payment_date] = params[:payment].nil? ? DateTime.now : params[:payment][:payment_date]

      if params[:payment][:id].nil?
        whitelisted[:creater_id] = current_user.try(:id)
        whitelisted[:creater_type] = "User"
      else
        whitelisted[:updater_id] = current_user.try(:id)
        whitelisted[:updater_type] = "User"
      end

    end
  end

  def find_payment
    @payment = Payment.find(params[:id])
  end

  def set_params_in_format
    params[:payment][:businesses_payment_attributes] = {}
    unless params[:payment][:business].nil?
      item = {}
      item[:business_id] = params[:payment][:business]
      params[:payment][:businesses_payment_attributes] = item
    end
  end

  def stop_activity
    Payment.public_activity_off
  end

end
