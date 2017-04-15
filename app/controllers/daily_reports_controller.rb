class DailyReportsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain

  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    result = {}
    authorize! :daily_payment, :daily_report
    # Getting filters data
    result[:locations] = all_available_locations
    # raise result[:locations].inspect
    result[:payment_types] = all_avail_payment_types
    start_date = params[:st_date].to_date unless params[:st_date].nil?

    loc_params = params[:bs_id].nil? ? nil : params[:bs_id].split(",").map { |a| a.to_i }
    p_type_params = params[:p_type_id].nil? ? nil : params[:p_type_id].split(",").map { |a| a.to_i }


    # Getting listing values
    result[:revenues] = []
    revenues = get_filter_wise_revenues(start_date, loc_params, p_type_params)
    revenues.each do |payment|
      item = {}
      item[:payent_id] = "0"*(6-payment.id.to_s.length)+ payment.id.to_s
      item[:datetime] = payment.payment_date.strftime("%d %b %Y")
      item[:patient] = payment.patient.full_name
      item[:patient_id] = payment.patient.try(:id)
      item[:sources] = []
      payment.payment_types_payments.active_payment_types_payments.where(["amount > ?", 0]).each do |obj|
        p_item = {}
        p_item[:source_name] = obj.payment_type.try(:name)
        p_item[:amount] = '% .2f'% (obj.amount.round(2)).to_f
        item[:sources] << p_item
      end
      item[:total] = '% .2f'% (payment.get_paid_amount.round(2)).to_f
      result[:revenues] << item
    end
    render :json => result
  end

  def daily_report_export
    begin
      authorize! :daily_payment, :daily_report
      result = {}
      start_date = params[:st_date].to_date unless params[:st_date].nil?
      loc_params = params[:bs_id].nil? ? nil : params[:bs_id].split(",").map { |a| a.to_i }
      p_type_params = params[:p_type_id].nil? ? nil : params[:p_type_id].split(",").map { |a| a.to_i }
      @payments = get_filter_wise_revenues(start_date, loc_params, p_type_params)
      respond_to do |format|
        format.html
        format.csv { render text: @payments.order('created_at asc').to_csv({}, false), status: 200 }
      end
    rescue Exception => e
      render :text => e.message
    end
  end

  def daily_report_pdf
    authorize! :daily_payment, :daily_report
    @result = []
    start_date = params[:st_date].to_date unless params[:st_date].nil?
    loc_params = params[:bs_id].nil? ? nil : params[:bs_id].split(",").map { |a| a.to_i }
    p_type_params = params[:p_type_id].nil? ? nil : params[:p_type_id].split(",").map { |a| a.to_i }
    revenues = get_filter_wise_revenues(start_date, loc_params, p_type_params)
    revenues.each do |payment|
      item = {}
      item[:payent_id] = "0"*(6-payment.id.to_s.length)+ payment.id.to_s
      item[:datetime] = payment.payment_date.strftime("%d %b %Y , %H:%M%p")
      item[:patient] = payment.patient.full_name
      item[:patient_id] = payment.patient.try(:id)
      item[:sources] =   []
      payment.payment_types_payments.active_payment_types_payments.where(["amount > ?", 0]).each do |obj|

        source_name = obj.payment_type.try(:name)
        amount = obj.amount
        item[:sources] << "#{source_name}:#{amount}"
      end
      item[:total] = payment.get_paid_amount
      @result << item
    end
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => 'pdf_name.pdf',
               :layout => '/layouts/pdf.html.erb',
               :disposition => 'inline',
               :template => '/daily_reports/daily_report_pdf',
               :show_as_html => params[:debug].present?,
               :footer => {right: '[page] of [topage]'}
      end
    end
  end

  def locations
    # authorize! :daily_payment, :daily_report
    result = []
    locations = @company.businesses.select('id , name')
    render :json => {locations: locations}
  end

  def chart_data
    # authorize! :daily_payment, :daily_report
    result = {}
    result[:series] = []
    cm_date = params[:dt].nil? ? Date.today : params[:dt].to_date
    unless params[:bus_id].nil?
      all_payment_types.each do |payment_type|
        item = {}
        obj_name = payment_type.name
        amount = calculate_revenue_on_a_specific_loc(payment_type, params[:bus_id], cm_date)
        amount = amount.to_s + "0" if amount.to_s.split(".")[1].length == 1 && amount > 0
        item[:name] = obj_name.to_s + " (#{amount})"
        item[:data] = amount
        result[:series] << item
      end
    end
    render :json => result
  end


  private

  def all_payment_types
    @company.payment_types.select("id ,  name ")
  end

  # filters methods
  def all_avail_payment_types
    result = []
    @company.payment_types.select("id ,  name ").each do |obj|
      item = {}
      item[:id] = obj.id
      item[:name] = obj.name
      result << item
    end
    return result
  end

  def all_available_locations
    result = []
    @company.businesses.select("id , name").each do |obj|
      item = {}
      item[:id] = obj.id
      item[:name] = obj.name
      result << item
    end
    return result
  end

  # ending here

  # calculate payment amount for a payment type on a specifc location - For chart purpose

  def calculate_revenue_on_a_specific_loc(p_type, loc_id, cm_date)
    payments = []
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      Invoice.unscoped do
        payments = p_type.payments.joins(:business , :invoices => [:user]).where(['users.id = ? AND businesses.id IN (?) AND payments.status = ? AND DATE(payments.payment_date) = ?', current_user.id , loc_id, true, cm_date]).uniq
      end
    else
      Invoice.unscoped do
        payments = p_type.payments.joins(:business).where(['businesses.id IN (?) AND payments.status= ? AND DATE(payments.payment_date) = ?', loc_id, true, cm_date]).uniq
      end
    end

    amount = 0.0
    payments.each do |payment|
      amount = amount + payment.get_paid_amount
    end
    return amount
  end

  def get_filter_wise_revenues(start_date=nil, bs_id=nil, p_type_id=nil)
    result = []
    if bs_id.nil? && p_type_id.nil?
      if start_date.nil?
        result = @company.payments.active_payment.where(["DATE(payment_date) = ?", Date.today])
      else
        result = @company.payments.active_payment.where(["DATE(payment_date) = ? ", start_date])
      end
    elsif !bs_id.nil? && p_type_id.nil?
      if start_date.nil?
        result = @company.payments.joins(:business).where(["businesses.id IN (?) AND payments.status = ? AND DATE(payment_date) = ?", bs_id, true, Date.today])
      else
        result = @company.payments.joins(:business).where(["businesses.id IN (?) AND payments.status = ? AND DATE(payment_date) = ?", bs_id, true, start_date])
      end
    elsif bs_id.nil? && !p_type_id.nil?
      if start_date.nil?
        result = @company.payments.joins(:payment_types).where(["payment_types.id IN (?) AND payments.status = ? AND DATE(payment_date) = ?", p_type_id, true], Date.today)
      else
        result = @company.payments.joins(:payment_types).where(["payment_types.id IN (?) AND payments.status = ? AND DATE(payment_date) = ? ", p_type_id, true, start_date])
      end
    elsif !bs_id.nil? && !p_type_id.nil?
      if start_date.nil?
        result = @company.payments.joins(:business, :payment_types).where(["businesses.id IN (?) AND payment_types.id IN (?) AND payments.status = ? AND DATE(payment_date) = ?", bs_id, p_type_id, true, Date.today])
      else
        result = @company.payments.joins(:business, :payment_types).where(["businesses.id IN (?) AND payment_types.id IN (?) AND payments.status = ? AND DATE(payment_date) = ? ", bs_id, p_type_id, true, start_date])
      end
    end
    return result
  end

end
