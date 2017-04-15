module TrialUserHelper
  include Opustime::Utility
  def customer_last_week(company)
    d1 = Time.now
    d2 = d1 - 1.week
    last_week = company.patients.where(["DATE(created_at)  <= ? AND  DATE(created_at) >= ?", d1, d2])
  end
  def trail_end_date(company)
  	d1 = company.subscription.created_at
  	trail_end = d1 + 1.month
  	return trail_end
  end
end
