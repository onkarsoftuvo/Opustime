module AdminNotificationHelper
  def customer_last_week(company)
    d1 = Time.now
    d2 = d1 - 1.week
    last_week = company.patients.where(["DATE(created_at)  <= ? AND  DATE(created_at) >= ?", d1, d2])
  end
end
