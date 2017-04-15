module AdminHelper

  def have_duplicate_email?(owner)
    return Owner.where(:email=>owner.email).count > 0 ? true : false
  end

  def get_value_from_cookies(key)
    if cookies[:sign_up].present?
      value_hash = YAML::load cookies[:sign_up]
      return value_hash["#{key}"]
    else
      return ''
    end
  end

end
