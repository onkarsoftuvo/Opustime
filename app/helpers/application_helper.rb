module ApplicationHelper

  def logged_in?
    !current_user.nil?
  end

  def log_out
    # destroy google authenticator session
    forget current_user
    reset_session
    @current_user = nil
  end

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = {value: user.remember_token, expires: Time.now + 30.minutes}
  end

  # Forgets a persistent session.
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def get_company
    Company.where(["company_name like ?", "%#{params[:comp_name]}%"]).first
  end

  def domain_name
    "#{request.protocol}#{request.host_with_port}"
  end

  def notification_count
    return Notification.total_unread_notifications(current_user)
  end

  def admin_error_json(error_arr, flag= false)
    error_msg = []
    error_arr.keys.each do |key|
      item= {}
      item[:error_name] = key.to_s.split("_").join(" ")
      item[:error_msg] = error_arr[key].first
      error_msg << item
    end
    return error_msg
  end

end
