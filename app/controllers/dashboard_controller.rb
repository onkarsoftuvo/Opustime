class DashboardController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain

  # Leter Remove this line
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    puts"=====index============"
    result = {}
    coming_date = Date.parse(params[:dt]) rescue nil
    custom_date = coming_date.nil? ? Date.today : params[:dt].to_date
    business = params[:bs_id].nil? ? (@company.businesses.head.first.try(:id)) : (params[:bs_id])

    # Checking dashboard permission
    ds_permission = DashboardPermission.last
    current_user_role = current_user.try(:user_role).try(:name)

    unless ds_permission.nil?
      result[:show_top_bar] = DashboardPermission.last[:dashboard_top][current_user_role]
      result[:view_appnt_report] = DashboardPermission.last[:dashboard_report][current_user_role]
    else
      result[:show_top_bar] = false
      result[:view_appnt_report] = false
    end

    # Getting tabbing info over here

    result[:booking_info] = get_booking_info(custom_date, business)
    result[:revenue_info] = get_revenue_info(custom_date, business)
    result[:patient_info] = get_patients_info(custom_date)
    result[:appointment_info] = get_appointment_info(custom_date, business)
    result[:product_info] = get_products_info(custom_date)
    result[:expense_info] = get_expense_info(custom_date)

    result[:current_user] = current_user.full_name

    result[:date] = custom_date
    ds_report = @company.dashboard_report
    ds_report = @company.create_dashboard_report if ds_report.nil?
    result[:graph_options] = {
                              :appnt => (ds_report.try(:appnt)&& (can? :manage, :report)),
                              :doctor => (ds_report.try(:doctor) && (can? :practitioner_revenue , :practitioner_report)),
                              :refer_src => (ds_report.try(:refer_type) && (can? :refer , :refer_patient)) ,
                              :revenue => (ds_report.try(:revenue) && (can? :payment_summary , :payment_report)),
                              :daily => (ds_report.try(:daily_report) && (can? :daily_payment, :daily_report))
                            }

    render :json => result
  end

  def locations
    result = []
    businesses = @company.businesses.select("id , name , address , city , state , country , pin_code , reg_name , reg_number")
    businesses.each do |bs|
      item = {}
      item[:id] = bs.id
      item[:name] = bs.name
      item[:city] = bs.city
      item[:country] = bs.get_country
      result << item
    end
    render :json => result
  end

  def appointments_reports
    final_result = {}
    result = []
    flag = true
    loc = params[:bs_id].nil? ? (@company.businesses.head.first.try(:id)) : (params[:bs_id])
    off_set = (params[:off_set].to_i < 0) ? 0 : (params[:off_set].to_i*2)
    coming_date = Date.parse(params[:dt]) rescue nil
    custom_date = coming_date.nil? ? Date.today : params[:dt].to_date

    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ? AND users.id = ?", loc , current_user.id ]).offset(off_set).limit(2)
      all_doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ? AND users.id = ?", loc , current_user.id])
    else
      doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ?", loc]).offset(off_set).limit(2)
      all_doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ?", loc]).offset(off_set)
    end



    if all_doctors.count > 3
     doctors = doctors
      flag = true
    else
      doctors = all_doctors
      flag = false
    end

    item = {}

    item[:key] = "PENDING"
    item[:values] = doctor_appointments(doctors, loc, custom_date, "pending")
    result << item

    item = {}
    item[:key] = "CANCELLED"
    item[:values] = doctor_appointments(doctors, loc, custom_date, "cancelled")
    result << item

    item = {}
    item[:key] = "PROCESSED"
    item[:values] = doctor_appointments(doctors, loc, custom_date, "processed")
    result << item

    final_result[:result] = result
    final_result[:next] = flag
    render :json => final_result
  end

  def sales_chart
    final_result = {}
    result = []
    loc = params[:bs_id].nil? ? (@company.businesses.head.first.try(:id)) : (params[:bs_id])
    off_set = (params[:off_set].to_i < 0) ? 0 : (params[:off_set].to_i*2)
    coming_date = Date.parse(params[:dt]) rescue nil
    custom_date = coming_date.nil? ? Date.today : params[:dt].to_date
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ? AND users.id = ? ", loc , current_user.id]).offset(off_set).limit(2)
      all_doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ? AND users.id = ?", loc , current_user.id ]).offset(off_set)
    else
      doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ?", loc]).offset(off_set).limit(2)
      all_doctors = @company.users.doctors.joins(:practitioner_avails).where(["business_id = ?", loc]).offset(off_set)
    end


    if all_doctors.count > 3
      doctors = doctors
      flag = true
    else
      doctors = all_doctors
      flag = false
    end

    item = {}
    item[:key] = "OPENED INVOICES"
    item[:values] = sales_chart_data(doctors, loc, custom_date, "opened")
    result << item

    item = {}
    item[:key] = "CLOSED INVOICES"
    item[:values] = sales_chart_data(doctors, loc, custom_date, "closed")
    result << item

    final_result[:result] = result
    final_result[:next] = flag
    render :json => final_result

  end

  def coming_appointments
    result = []
    loc = params[:bs_id].nil? ? (@company.businesses.head.first.try(:id)) : (params[:bs_id])
    coming_date = Date.parse(params[:dt]) rescue nil
    custom_date = coming_date.nil? ? Date.today : params[:dt].to_date
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      appnt = @company.appointments.active_appointment.joins(:business).where([" appointments.user_id = ? AND businesses.id = ? AND Date(appointments.appnt_date) = ? ", current_user.id , loc, custom_date]).order("appnt_time_start asc")
    else
      appnt = @company.appointments.active_appointment.joins(:business).where(["businesses.id = ? AND Date(appointments.appnt_date) = ? ", loc, custom_date]).order("appnt_time_start asc")
    end

    tm_period = []
    appnt.each do |apnt|
      tm_period << apnt.appnt_time_start.strftime("%H:%M%p")
    end

    tm_period = tm_period.uniq
    temp = {}
    tm_period.each do |tm|
      temp[tm] = []
      appnt.each do |apnt|
        if (tm == apnt.appnt_time_start.strftime("%H:%M%p")) && (temp.has_key?(tm))
          temp[tm] << apnt.id
        end
      end

    end
    temp.each_pair do |key, val|
      data = {}
      data[:appnts] = []
      val.each do |apnt_id|
        apnt = Appointment.find(apnt_id)
        start_time = apnt.appnt_time_start
        end_time = apnt.appnt_time_end
        data[:time_period] = start_time.strftime("%H:%M")
        data[:meridian] = end_time.strftime("%p")
        current = Time.new
        t1 = Time.new(current.year, current.month, current.day, start_time.strftime("%H"), start_time.strftime("%M"))
        t2 = Time.new(current.year, current.month, current.day, end_time.strftime("%H"), end_time.strftime("%M"))


        item = {}
        item[:high_light] = (current > t1 && current < t2)
        item[:start_at] = apnt.appnt_time_start.strftime("%H:%M%p")

        item[:end_at] = apnt.appnt_time_end.strftime("%H:%M%p")
        item[:color_code] = (apnt.try(:appointment_type).try(:color_code).nil? ? "#e26c60" : (apnt.try(:appointment_type).try(:color_code)))
        item[:doctor_name] = apnt.try(:user).try(:full_name)
        item[:patient_name] = apnt.try(:patient).try(:full_name)
        item[:patient_id] = apnt.try(:patient).try(:id)
        item[:appointment_id] = apnt.try(:id)
        if (apnt.cancellation_time.nil? && apnt.status == true)
          apnt_status = apnt.patient_arrive == true ? "A" : "NA"
        else
          apnt_status = "C"
        end

        item[:appnt_status] = apnt_status
        data[:appnts] << item
      end
      result << data

    end
    render :json => result
  end

  def product_sale_chart
    result = []
    loc = params[:bs_id].nil? ? (@company.businesses.head.first.try(:id)) : (params[:bs_id])
    coming_date = Date.parse(params[:dt]) rescue nil
    custom_date = coming_date.nil? ? Date.today : params[:dt].to_date

    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      invoices = @company.invoices.active_invoice.joins(:user , :business).where([" users.id = ? AND businesses.id = ? AND DATE(invoices.issue_date) = ? ", current_user.id  , loc, custom_date])
    else
      invoices = @company.invoices.active_invoice.joins(:business).where(["businesses.id = ? AND invoices.issue_date = ? ", loc, custom_date])
    end


    if params[:chart_type] == "overall"
      products_amount = 0.0
      service_amount = 0.0
      invoices.each do |invoice|
        invoice.invoice_items.each do |inv_item|
          products_amount = products_amount + inv_item.total_price if inv_item.item_type == "Product"
          service_amount = service_amount + inv_item.total_price if inv_item.item_type == "BillableItem"
        end
      end
      result = [{name: "product", amount: products_amount}, {name: "service", amount: service_amount}]
    else
      if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
        bill_items = @company.invoice_items.joins(:invoice => [:user]).where([" users.id = ? AND invoice_items.item_type = ? AND invoice_items.invoice_id IN (?)", current_user.id , "BillableItem", invoices.ids]).group("invoice_items.item_id").select("invoice_items.item_id , SUM(total_price) as total")
      else
        bill_items = @company.invoice_items.where(["item_type=? AND invoice_id IN (?)", "BillableItem", invoices.ids]).group("item_id").select("item_id , SUM(total_price) as total")
      end

      bill_items.each do |b_item|
        item = {}
        item[:name] = BillableItem.find_by_id(b_item.item_id).try(:name)
        item[:amount] = b_item.total
        result << item
      end

    end
    render :json => result
  end

  def report_options
    ds_report = @company.dashboard_report
    if ds_report.nil?
      ds_report = @company.create_dashboard_report()
    end
    if params[:report_options][:obj] == "appnt" && ([true, false, "true", "false"].include? (params[:report_options][:val]))
      ds_report.update_attributes(appnt: params[:report_options][:val])
    elsif params[:report_options][:obj] == "dc" && ([true, false, "true", "false"].include? (params[:report_options][:val]))
      ds_report.update_attributes(doctor: params[:report_options][:val])
    elsif params[:report_options][:obj] == "revenue" && ([true, false, "true", "false"].include? (params[:report_options][:val]))
      ds_report.update_attributes(revenue: params[:report_options][:val])
    elsif params[:report_options][:obj] == "refer_type" && ([true, false, "true", "false"].include? (params[:report_options][:val]))
      ds_report.update_attributes(refer_type: params[:report_options][:val])
    elsif params[:report_options][:obj] == "daily_report" && ([true, false, "true", "false"].include? (params[:report_options][:val]))
      ds_report.update_attributes(daily_report: params[:report_options][:val])
    end
    if ds_report.valid?
      result = {flag: true}
    else
      result = {flag: false}

    end
    render :json => result
  end

  def get_report_options
    ds_report = @company.dashboard_report
    if ds_report.nil?
      ds_report = @company.create_dashboard_report()
    end
    result = {}
    result[:appnt] = (ds_report.appnt)
    result[:doctor] = (ds_report.doctor)
    result[:revenue] = (ds_report.revenue)
    result[:refer_type] = (ds_report.refer_type)
    result[:daily_report] = (ds_report.daily_report)
    render :json => result
  end

  def get_activity
    result = []
    coming_date = params[:dt].to_date
    if coming_date.nil?
      inv_activities = []
      payment_activities = []
      expense_activities = []
      appointment_activities = []
      sms_activities = []

      if params[:tb].to_i == 1
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          appointment_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ? AND activities.owner_id = ?", "Appointment", @company.id, params[:bs_id], current_user.id ]).order("created_at desc")
        else
          appointment_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ?", "Appointment", @company.id, params[:bs_id]]).order("created_at desc")
        end

      elsif params[:tb].to_i == 2
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          inv_activities = PublicActivity::Activity.joins(:business).where([" activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ? ", current_user.id , "Invoice", @company.id, params[:bs_id]]).order("created_at desc")
        else
          inv_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ? ", "Invoice", @company.id, params[:bs_id]]).order("created_at desc")
        end

      elsif params[:tb].to_i == 3
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          payment_activities = PublicActivity::Activity.joins(:business).where(["activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ? ", current_user.id , "Payment", @company.id, params[:bs_id]]).order("created_at desc")
        else
          payment_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ? ", "Payment", @company.id, params[:bs_id]]).order("created_at desc")
        end

      elsif params[:tb].to_i == 4
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          expense_activities = PublicActivity::Activity.joins(:business).where(["activities.owner_id = ? AND trackable_type = ? AND company_id = ? ", current_user.id , "Expense", @company.id]).order("created_at desc")
        else
          expense_activities = PublicActivity::Activity.joins(:business).where(["trackable_type = ? AND company_id = ? ", "Expense", @company.id]).order("created_at desc")
        end

      elsif params[:tb].to_i == 5
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          sms_activities = PublicActivity::Activity.where(["activities.owner_id = ? AND  trackable_type = ? AND company_id = ? ", current_user.id , "SmsLog", @company.id]).order("created_at desc")
        else
          sms_activities = PublicActivity::Activity.where(["trackable_type = ? AND company_id = ? ", "SmsLog", @company.id]).order("created_at desc")
        end

      else
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          appointment_activities = PublicActivity::Activity.joins(:business).where(["activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ?", current_user.id , "Appointment", @company.id, params[:bs_id]]).order("created_at desc")
        else
          appointment_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND activities.business_id= ?", "Appointment", @company.id, params[:bs_id]]).order("created_at desc")
        end

      end
    else
      inv_activities = []
      payment_activities = []
      expense_activities = []
      appointment_activities = []
      sms_activities = []

      if params[:tb].to_i == 1
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          appointment_activities = PublicActivity::Activity.joins(:business).where([" activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", current_user.id , "Appointment", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        else
          appointment_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", "Appointment", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        end

      elsif params[:tb].to_i == 2
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          inv_activities = PublicActivity::Activity.joins(:business).where(["activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", current_user.id , "Invoice", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        else
          inv_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", "Invoice", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        end

      elsif params[:tb].to_i == 3
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          payment_activities = PublicActivity::Activity.joins(:business).where(["activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", current_user.id ,  "Payment", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        else
          payment_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", "Payment", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        end

      elsif params[:tb].to_i == 4
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          expense_activities = PublicActivity::Activity.joins(:business).where(["activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", current_user.id ,  "Expense", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        else
          expense_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", "Expense", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        end

      elsif params[:tb].to_i == 5
          if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          sms_activities = PublicActivity::Activity.where(["activities.owner_id = ? AND trackable_type = ? AND company_id = ? AND DATE(created_at) = ? ", current_user.id , "SmsLog", @company.id, coming_date]).order("created_at desc")
        else
          sms_activities = PublicActivity::Activity.where(["trackable_type = ? AND company_id = ? AND DATE(created_at) = ? ", "SmsLog", @company.id, coming_date]).order("created_at desc")
        end
      else
        if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
          appointment_activities = PublicActivity::Activity.joins(:business).where(["activities.owner_id = ? AND activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", current_user.id ,"Appointment", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        else
          appointment_activities = PublicActivity::Activity.joins(:business).where(["activities.trackable_type = ? AND activities.company_id = ? AND DATE(activities.created_at) = ? AND activities.business_id= ? ", "Appointment", @company.id, coming_date, params[:bs_id]]).order("created_at desc")
        end

      end
    end

    # Making Invoice activity logs
    inv_item = {}
    if inv_activities.length > 0
      inv_item[:obj_name] = "Invoice"
      inv_item[:data] = []
      inv_activities.each do |obj|
        item = {}
        item[:created_at] = obj.updated_at.strftime("%H:%M%p")
        item[:issue_date] = (obj.parameters[:issue_date].nil?) ? nil : (obj.parameters[:issue_date].strftime("%d-%m-%Y"))
        item[:creator] = obj.owner.try(:full_name)
        item[:obj_type] = obj.trackable_type
        item[:obj_id] = obj.trackable.try(:formatted_id)
        item[:action] = obj.key.split(".")[1]
        item[:new_amount] = (obj.parameters[:other].nil?) ? nil : (obj.parameters[:other][:new_amount])
        item[:old_amount] = (obj.parameters[:other].nil?) ? nil : (obj.parameters[:other][:old_amount])
        item[:total] = (obj.parameters[:total_amount].present?) ? (obj.parameters[:total_amount]) : (obj.trackable.try(:total_amount))
        item[:patient_id] = (obj.parameters[:patient_id].present?) ? (obj.parameters[:patient_id]) : (obj.trackable.patient.id)

        item[:patient_name] = (obj.parameters[:patient_name].present?) ? (obj.parameters[:patient_name]) : (obj.trackable.patient.full_name)
        inv_item[:data] << item
      end
      result << inv_item

    else
      inv_item[:obj_name] = "Invoice"
      inv_item[:data] = {data: false}
      result << inv_item
    end

    # Making Payment API

    pay_item = {}
    if payment_activities.length > 0
      pay_item[:obj_name] = "Payment"
      pay_item[:data] = []
      payment_activities.each do |obj|
        item = {}
        item[:created_at] = obj.updated_at.strftime("%H:%M%p")
        item[:creator] = obj.owner.try(:full_name)
        item[:obj_type] = obj.trackable_type
        item[:obj_id] = obj.trackable.try(:formatted_id)
        item[:action] = obj.key.split(".")[1]
        item[:patient_id] = (obj.parameters[:patient_id].present?) ? (obj.parameters[:patient_id]) : (obj.trackable.patient.id)
        item[:patient_name] = (obj.parameters[:patient_name].present?) ? (obj.parameters[:patient_name]) : (obj.trackable.patient.full_name)
        item[:new_amount] = (obj.parameters[:other].nil?) ? nil : (obj.parameters[:other][:new_amount])
        item[:old_amount] = (obj.parameters[:other].nil?) ? nil : (obj.parameters[:other][:old_amount])
        item[:total] = (obj.parameters[:total_amount].present?) ? (obj.parameters[:total_amount]) : (obj.trackable.deposited_amount_of_invoice)
        item[:used_invoices] = (obj.parameters[:used_invoices].present?) ? (obj.parameters[:used_invoices]) : nil
        item[:payment_methods] = (obj.parameters[:payment_methods].present?) ? (obj.parameters[:payment_methods]) : nil
        pay_item[:data] << item
      end
      result << pay_item
    else
      pay_item[:obj_name] = "Payment"
      pay_item[:data] = {data: false}
      result << pay_item
    end

    # Making Expense API

    exp_item = {}
    if expense_activities.length > 0
      exp_item[:obj_name] = "Expense"
      exp_item[:data] = []
      expense_activities.each do |obj|
        item = {}
        item[:created_at] = obj.updated_at.strftime("%H:%M%p")
        item[:creator] = obj.owner.try(:full_name)
        item[:obj_type] = obj.trackable_type
        item[:obj_id] = obj.trackable.try(:formatted_id)
        item[:action] = obj.key.split(".")[1]
        item[:include_tax] = (obj.parameters[:include_tax].present?) ? (obj.parameters[:include_tax]) : (obj.trackable.tax_amount > 0)
        item[:business_id] = (obj.parameters[:bs_id].present?) ? (obj.parameters[:bs_id]) : (obj.trackable.business.id)
        item[:business_name] = (obj.parameters[:bs_name].present?) ? (obj.parameters[:bs_name]) : (obj.trackable.business.name)

        item[:new_amount] = (obj.parameters[:other].nil?) ? nil : (obj.parameters[:other][:new_amount])
        item[:old_amount] = (obj.parameters[:other].nil?) ? nil : (obj.parameters[:other][:old_amount])
        unless obj.key.include?'delete'
          item[:total] = (obj.parameters[:total_amount].present?) ? (obj.parameters[:total_amount]) : (obj.trackable.deposited_amount_of_invoice)
        else
          item[:total] = (obj.parameters[:total_amount].present?) ? (obj.parameters[:total_amount]) : (obj.trackable.total_expense)
        end

        exp_item[:data] << item
      end
      result << exp_item
    else
      exp_item[:obj_name] = "Expense"
      exp_item[:data] = {data: false}
      result << exp_item
    end

    # APIs FOR Appointment
    appnt_item = {}
    if appointment_activities.length > 0
      appnt_item[:obj_name] = "Appointment"
      appnt_item[:data] = []
      appointment_activities.each do |obj|
        item = {}
        item[:created_at] = obj.updated_at.strftime('%I:%M')
        key = obj.key.split(".")[1]
        if (key =='Reschedule') || (key =='patient_status') || (key =='appnt_status')
          item[:creator] = (obj.trackable.try(:rescheduler).try(:full_name))
        elsif (key =="Cancel")
          item[:creator] = (obj.trackable.try(:canceller).try(:full_name))
        else
          item[:creator] = obj.owner.try(:full_name)
        end

        item[:obj_type] = obj.trackable_type
        item[:obj_id] = obj.trackable.try(:formatted_id)

        item[:action] = key
        item[:patient_id] = (obj.parameters[:patient_id].nil? ? obj.trackable.patient.try(:id) : obj.parameters[:patient_id])
        item[:patient_name] = (obj.parameters[:patient_name].nil? ? obj.trackable.patient.try(:full_name) : obj.parameters[:patient_name])
        item[:doctor_id] = (obj.parameters[:doctor_id].nil? ? obj.trackable.user.try(:id) : obj.parameters[:doctor_id])
        item[:doctor_name] = (obj.parameters[:doctor_name].nil? ? obj.trackable.user.try(:full_name) : obj.parameters[:doctor_name])
        item[:booking_time] = (obj.parameters[:booking_date].nil? ? obj.trackable.try(:date_and_time_without_name) : obj.parameters[:booking_date])

        item[:new_bk_str_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_str_time]
        item[:old_bk_str_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_str_time]

        item[:new_bk_end_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_end_time]
        item[:old_bk_end_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_end_time]

        item[:new_date] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_date]
        item[:old_date] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_date]

        item[:old_patient_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_patient_status]
        item[:new_patient_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_patient_status]

        item[:old_appnt_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_appnt_status]
        item[:new_appnt_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_appnt_status]
        item[:cancel_reason] = obj.parameters[:reason].nil? ? nil : obj.parameters[:reason]


        item[:total_appnts] = (obj.parameters[:total_appnts].nil? ? 1 : obj.parameters[:total_appnts])
        item[:type_wise] = obj.parameters[:type_wise]

        appnt_item[:data] << item
      end
      result << appnt_item
    else
      appnt_item[:obj_name] = "Appointment"
      appnt_item[:data] = {data: false}
      result << appnt_item
    end

    # Making SMS Logs API

    sms_item = {}
    if sms_activities.length > 0
      sms_item[:obj_name] = "SmsLog"
      sms_item[:data] = []
      sms_activities.each do |obj|
        item = {}
        if obj.trackable.nil?
          puts 'heer'
        end
        item[:created_at] = obj.updated_at.strftime("%H:%M%p")
        item[:obj_type] = obj.trackable_type
        item[:owner_type] = obj.owner_type
        item[:action] = obj.key.split(".")[1]
        item[:sender_id] = obj.parameters[:sender_id]
        item[:sender_name] = obj.parameters[:sender_name]
        item[:receiver_id] = obj.parameters[:receiver_id]
        item[:sender_type] = obj.parameters[:obj_type]
        item[:receiver_name] = obj.parameters[:receiver_name]
        item[:dsg_no] = obj.parameters[:dsg_no]
        item[:sms_text] = obj.parameters[:sms]
        #item[:obj_type] = obj.parameters[:obj_type]
        item[:sms_status] = obj.trackable.try(:status)

        sms_item[:data] << item
      end
      result << sms_item
    else
      sms_item[:obj_name] = "SmsLog"
      sms_item[:data] = {data: false}
      result << sms_item
    end

    render :json => result

  end

  def admin_ds_permission
    ds_permission = DashboardPermission.last
    role_name = current_user.user_role.try(:name)
    role_name = current_user.role if current_user.user_role.nil?
    result = {}
    unless ds_permission.nil?
      result[:top] =  ds_permission.dashboard_top[role_name].to_bool
      result[:report] = ds_permission.dashboard_report[role_name].to_bool
      result[:appointment] = ds_permission.dashboard_appnt[role_name].to_bool
      result[:activity] = ds_permission.dashboard_activity[role_name].to_bool
      result[:chart_practi] = ds_permission.dashboard_chartpracti[role_name].to_bool
      result[:chart_product] = ds_permission.dashboard_chartproduct[role_name].to_bool
    else
      result[:top] = result[:report] = result[:appointment] = result[:activity] = true
      result[:chart_practi] = result[:chart_product] = true
    end
    render :json => { :ds_permission => result }
  end

  private

  # Revenue calculation start from here

  def get_revenue_info(custom_date, loc_id)
    result = {}
    result[:total_revenues] = total_revenue_today(custom_date, loc_id).round(2)
    per_val = get_percentage_info(custom_date, loc_id).round(2)
    result[:percentage_info] = per_val
    result[:mode] = check_stable_status(per_val)
    return result
  end

  def total_revenue_today(custom_date, loc_id)
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      today_payments = @company.payments.active_payment.joins(:business , :invoices =>[:user] ).where(["businesses.id = ? AND DATE(payments.payment_date) = ? AND users.id = ?", loc_id, custom_date , current_user.id]).uniq
    else
      today_payments = @company.payments.active_payment.joins(:business).where(["businesses.id = ? AND DATE(payments.payment_date) = ?", loc_id, custom_date]).uniq
    end
    amount = revenue_total(today_payments)
  end

  def get_percentage_info(custom_date, loc_id)
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      yesterday_payments = @company.payments.active_payment.joins(:business , :invoices =>[:user]).where(["businesses.id = ? AND DATE(payments.payment_date) = ? AND users.id = ?", loc_id, (custom_date - 1.day) , current_user.id])
      today_payments = @company.payments.active_payment.joins(:business , :invoices =>[:user]).where(["businesses.id = ? AND DATE(payments.payment_date) = ? AND users.id = ? ", loc_id, custom_date , current_user.id])
    else
      yesterday_payments = @company.payments.active_payment.joins(:business).where(["businesses.id = ? AND DATE(payments.payment_date) = ?", loc_id, custom_date - 1.day])
      today_payments = @company.payments.active_payment.joins(:business).where(["businesses.id = ? AND DATE(payments.payment_date) = ?", loc_id, custom_date])
    end

    today_revenues = revenue_total(today_payments)
    yesterday_revenues = revenue_total(yesterday_payments)

    # calculate percentage of increament/decreament in revenue
    if yesterday_revenues > 0 && today_revenues == 0
      per_val = -100
    elsif yesterday_revenues == 0 && today_revenues > 0
      per_val = 100
    elsif yesterday_revenues == 0 && today_revenues == 0
      per_val = 0
    else
      per_val = (((today_revenues- yesterday_revenues).to_f)*100.0)/yesterday_revenues
    end
    return per_val
  end

  def revenue_total(payments=[])
    amount = 0
    payments.each do |payment|
      amount = amount + payment.get_paid_amount
    end
    return amount
  end

  # Revenue calculation ending here

  # Booking calculation start from here
  def get_booking_info(custom_date, loc_id)
    result = {}
    result[:total_booking] = total_booking_today(custom_date, loc_id).round(2)
    per_val = get_booking_percentage(custom_date, loc_id)
    result[:percentage_info] = per_val
    result[:mode] = check_stable_status(per_val)
    return result
  end

  def total_booking_today(custom_date, loc_id)
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.created_at) = ? AND user_id = ?", loc_id, custom_date , current_user.id]).uniq.count
    else
      @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.created_at) = ?", loc_id, custom_date]).uniq.count
    end

  end

  def get_booking_percentage(custom_date, loc_id)
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      today_booking = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.created_at) = ? AND user_id = ?", loc_id, custom_date , current_user.id]).uniq.count
      yesterday_booking = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.created_at) = ? AND user_id = ?", loc_id, custom_date-1.day , current_user.id]).uniq.count
    else
      today_booking = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.created_at) = ?", loc_id, custom_date]).uniq.count
      yesterday_booking = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.created_at) = ?", loc_id, custom_date-1.day]).uniq.count
    end

    # calculate percentage of increament/decreament in Booking
    if yesterday_booking > 0 && today_booking == 0
      per_val = -100
    elsif yesterday_booking == 0 && today_booking > 0
      per_val = 100
    elsif yesterday_booking == 0 && today_booking == 0
      per_val = 0
    else
      per_val = ((((today_booking- yesterday_booking).to_f)*100.0)/yesterday_booking).round(2)
    end
    return per_val
  end

  # Booking calculation ending over here

  # Patient calculation start from here
  def get_patients_info(custom_date)
    result = {}
    result[:total_patients] = total_patients_today(custom_date).round(2)
    per_val = get_patients_percentage(custom_date)
    result[:percentage_info] = per_val
    result[:mode] = check_stable_status(per_val)
    return result
  end

  def total_patients_today(custom_date)
    @company.patients.active_patient.where(["DATE(patients.created_at)= ? ", custom_date]).count
  end

  def get_patients_percentage(custom_date)
    today_patients = @company.patients.active_patient.where(["DATE(patients.created_at)= ? ", custom_date]).count
    yesterday_patients = @company.patients.active_patient.where(["DATE(patients.created_at)= ? ", custom_date - 1.day]).count
    # calculate percentage of increament/decreament in patients
    if yesterday_patients > 0 && today_patients == 0
      per_val = -100
    elsif yesterday_patients == 0 && today_patients > 0
      per_val = 100
    elsif yesterday_patients == 0 && today_patients == 0
      per_val = 0
    else
      per_val = ((((today_patients- yesterday_patients).to_f)*100.0)/yesterday_patients).round(2)
    end
    return per_val
  end

  # Patients calculation ending over here

  # Appointment calculation start from here
  def get_appointment_info(custom_date, loc_id)
    result = {}
    result[:total_appointments] = total_appointments_today(custom_date, loc_id).round(2)
    per_val = get_appointments_percentage(custom_date, loc_id)
    result[:percentage_info] = per_val
    result[:mode] = check_stable_status(per_val)
    return result
  end

  def total_appointments_today(custom_date, loc_id)
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.appnt_date) = ? AND appointments.user_id = ? ", loc_id, custom_date , current_user.id]).uniq.count
    else
      @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.appnt_date) = ? ", loc_id, custom_date]).uniq.count
    end

  end

  def get_appointments_percentage(custom_date, loc_id)
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      today_appnts = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.appnt_date) = ? AND appointments.user_id = ? ", loc_id, custom_date , current_user.id]).uniq.count
      yesterday_appnts = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.appnt_date) = ? AND appointments.user_id = ?", loc_id, custom_date- 1.day , current_user.id]).uniq.count
    else
      today_appnts = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.appnt_date) = ? ", loc_id, custom_date]).count
      yesterday_appnts = @company.appointments.active_appointment.joins(:business).where([" businesses.id = ? AND DATE(appointments.appnt_date) = ? ", loc_id, custom_date- 1.day]).count
    end

    # calculate percentage of increament/decreament in appointments
    if yesterday_appnts > 0 && today_appnts == 0
      per_val = -100
    elsif yesterday_appnts == 0 && today_appnts > 0
      per_val = 100
    elsif yesterday_appnts == 0 && today_appnts == 0
      per_val = 0
    else
      per_val = ((((today_appnts- yesterday_appnts).to_f)*100.0)/yesterday_appnts).round(2)
    end
    return per_val
  end

  # Appointment calculation ending over here

  # products calculation start from here

  def get_products_info(custom_date)
    result = {}
    result[:total_products] = total_products_today(custom_date).round(2)
    per_val = get_products_percentage(custom_date)
    result[:percentage_info] = per_val
    result[:mode] = check_stable_status(per_val)
    return result
  end

  def total_products_today(custom_date)
    # @company.products.active_products.where(["DATE(products.created_at) = ? ", custom_date]).count
    @company.invoice_items.where(["item_type=? AND DATE(invoice_items.created_at)=?" , "Product" , custom_date]).map(&:quantity).sum
  end

  def get_products_percentage(custom_date)
    today_products = @company.invoice_items.where(['item_type=? AND DATE(invoice_items.created_at)=?' , 'Product' , custom_date]).map(&:quantity).sum
    yesterday_products = @company.invoice_items.where(['item_type=? AND DATE(invoice_items.created_at) !=?' , 'Product' , custom_date])
    if yesterday_products.length > 0
      yesterday_products = yesterday_products.average(:quantity).truncate(2).to_s('F').to_f
    else
      yesterday_products = 0
    end
    # yesterday_products = @company.products.active_products.where(["DATE(products.created_at) = ? ", custom_date - 1.day]).count
    # calculate percentage of increament/decreament in products
    if yesterday_products > 0 && today_products == 0
      per_val = -100
    elsif yesterday_products == 0 && today_products > 0
      per_val = 100
    elsif yesterday_products == 0 && today_products == 0
      per_val = 0
    else
      per_val =
          ((((today_products).to_f)*100.0)/yesterday_products).round(2)
    end
    return per_val
  end

  # products calculation ending over here

  # expenses calculation start from here
  def get_expense_info(custom_date)
    result = {}
    result[:total_expenses] = total_expenses_today(custom_date).round(2)
    per_val = get_expenses_percentage(custom_date)
    result[:percentage_info] = per_val
    result[:mode] = check_stable_status(per_val)
    return result
  end

  def total_expenses_today(custom_date)
    @company.expenses.active_expense.where(["DATE(expenses.expense_date) = ? ", custom_date]).uniq.count
  end

  def get_expenses_percentage(custom_date)
    today_expense = @company.expenses.active_expense.where(["DATE(expenses.expense_date) = ? ", custom_date]).uniq.count
    yesterday_expense = @company.expenses.active_expense.where(["DATE(expenses.expense_date) = ? ", custom_date-1]).uniq.count
    # calculate percentage of increament/decreament in expense
    if yesterday_expense > 0 && today_expense == 0
      per_val = -100
    elsif yesterday_expense == 0 && today_expense > 0
      per_val = 100
    elsif yesterday_expense == 0 && today_expense == 0
      per_val = 0
    else
      per_val = ((((today_expense- yesterday_expense).to_f)*100.0)/yesterday_expense).round(2)
    end
    return per_val
  end

  # expenses calculation ending over here


  def check_stable_status(per_val)
    change_status = "stable"
    if per_val < 0
      change_status = "down"
    elsif per_val > 0
      change_status = "up"
    end
    return change_status
  end

  # Get doctor's appointments - pending , processed , cancelled

  def doctor_appointments(doctors, loc, date = Date.today, appnt_type)
    result = []
    if appnt_type == "pending"
      doctors.each do |doctor|
        item = {}
        item[:x] = doctor.full_name
        item[:y] = doctor.total_pending_appnts(loc, date)
        result << item
      end
    elsif appnt_type == "cancelled"
      doctors.each do |doctor|
        item = {}
        item[:x] = doctor.full_name
        item[:y] = doctor.total_cancelled_appnts(loc, date)
        result << item
      end
    elsif appnt_type == "processed"
      doctors.each do |doctor|
        item = {}
        item[:x] = doctor.full_name
        item[:y] = doctor.total_processed_appnts(loc, date)
        result << item
      end
    end
    return result
  end

  def sales_chart_data(doctors, loc, date = Date.today, sale_status)
    result = []
    if sale_status == "opened"
      doctors.each do |doctor|
        item = {}
        item[:x] = doctor.full_name
        item[:y] = doctor.opened_invoices_amount(loc, date)
        result << item
      end
    elsif sale_status == "closed"
      doctors.each do |doctor|
        item = {}
        item[:x] = doctor.full_name
        item[:y] = doctor.closed_invoices_amount(loc, date)
        result << item
      end
    end
    return result
  end


end
