module BusinessReportHelper
  def customer_last_week(company)
    d1 = Time.now
    d2 = d1 - 1.week
    last_week = company.patients.where(["DATE(created_at)  <= ? AND  DATE(created_at) >= ?", d1, d2])
  end

  def customer_last_month(cmp)
    d1 = Time.now
    d2 = d1 - 1.month
    last_month = cmp.patients.where(["DATE(created_at)  <= ? AND  DATE(created_at) >= ?", d1, d2])
  end

  def customise_state(country_sym)
    a = []
    country_sym.each_pair do |k,v|
      a << [v, k.to_s,:id => k]
      # a << [v, k.to_s ]
    end
    return a
  end

  def businesses_name(comp)
    comp.businesses
  end

  def current_class?(test_path)
    return 'active' if request.path == test_path
    ''
  end

  def object_wise_communication_logs(comp, obj_type)
    comp.communications.where(["communications.comm_type= ?", obj_type])
  end

end
    