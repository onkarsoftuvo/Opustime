module UsersHelper

  def get_user_instance(user_object, user_info, user_refer, user_avail, user_day, user_break)
    result ={}
    result[:title] =user_object.title
    result[:first_name] =user_object.first_name
    result[:last_name] =user_object.last_name
    result[:email] =user_object.email
    result[:is_doctor] =user_object.is_doctor
    result[:phone] =user_object.phone
    result[:time_zone] =user_object.time_zone
    result[:auth_factor] =user_object.auth_factor
    result[:role] =user_object.role
    result[:acc_active] =user_object.acc_active
    result[:password] = nil
    result[:password_confirmation] =nil
    result[:practi_info_attributes] = {}
    #  ADDING USER INFO NEW OBJECT
    user_info_item = {}
    user_info_item[:designation] = user_info.designation
    user_info_item[:desc] = user_info.desc
    user_info_item[:default_type] = user_info.default_type
    user_info_item[:notify_by] = user_info.notify_by
    user_info_item[:cancel_time] = user_info.cancel_time
    user_info_item[:is_online] = user_info.is_online
    user_info_item[:appointment_services] = []
    user_info_item[:allow_external_calendar] = user_info.allow_external_calendar

    user_info_item[:practi_refers_attributes] = []
    #  ADDING PRACTI REFERS
    user_refer_item = {}
    user_refer_item[:ref_type] = user_refer.ref_type
    user_refer_item[:number] = user_refer.number
    user_refer_item[:business_id] = user_refer.business_id
    user_info_item[:practi_refers_attributes] << user_refer_item
    #  END
    user_info_item[:practitioner_avails_attributes] = []
    result[:practi_info_attributes] = user_info_item
    return result
  end

  def get_user_info_for_edit(user)
    result = {}
    result[:id] = user.id
    result[:title] = user.title
    result[:first_name] = user.first_name
    result[:last_name] = user.last_name
    result[:email] = user.email
    result[:is_doctor] = user.is_doctor
    result[:phone] = user.phone.phony_formatted(format: :international, spaces: '-') rescue nil
    result[:time_zone] = user.time_zone
    result[:auth_factor] = user.auth_factor
    result[:role] = user.role
    result[:acc_active] = user.acc_active
    result[:logo] = user.logo
    #   user info
    result[:practi_info_attributes] = {}
    # if user.is_doctor
    user_info = user.practi_info
    unless user_info.nil?
      user_info_item = {}
      user_info_item[:id] = user_info.id
      user_info_item[:designation] = user_info.designation
      user_info_item[:desc] = user_info.desc
      unless user_info.default_type.nil?
        df_type = user_info.default_type.to_i == 0 ? user_info.default_type : user_info.default_type.to_i
      else
        df_type = "N/A"
      end
      user_info_item[:default_type] = df_type
      user_info_item[:notify_by] = user_info.notify_by
      user_info_item[:cancel_time] = user_info.cancel_time
      user_info_item[:is_online] = user_info.is_online
      user_info_item[:allow_external_calendar] = user_info.allow_external_calendar
      user_info_item[:external_calendar_path] = request.base_url+"/settings/users/#{user.id}/ical.ics"

      user_info_item[:appointment_services] = []
      selected_appnt_ids = []
      # Getting selected appointment types for current user
      selected_appnt_types = AppointmentTypesUser.where(["user_id = ? AND appointment_type_id IS NOT ?", user.id, nil])
      selected_appnt_types.each do |appnt_type|
        item = {}
        item[:id] = appnt_type.id
        item[:appointment_type_id] = appnt_type.appointment_type.try(:id)
        selected_appnt_ids << appnt_type.appointment_type.try(:id)
        item[:name] = appnt_type.appointment_type.try(:name)
        item[:is_selected] = true
        user_info_item[:appointment_services] << item
      end
      # Getting unselected appointment types for current user
      selected_appnt_ids = selected_appnt_ids.compact
      if selected_appnt_ids.count == 0
        unselected_appnt_types = user.company.appointment_types
      else
        unselected_appnt_types = user.company.appointment_types.where(["appointment_types.id NOT IN (?)", selected_appnt_ids])
      end

      unselected_appnt_types.each do |appnt_type|
        item = {}
        item[:appointment_type_id] = appnt_type.id
        item[:name] = appnt_type.name
        item[:is_selected] = false
        user_info_item[:appointment_services] << item
      end
      user_info_item[:appointment_services] = user_info_item[:appointment_services].sort_by { |hsh| hsh[:appointment_type_id] }

      user_info_item[:practi_refers_attributes] = []
      #  user refers getting here
      user_info.practi_refers.each do |user_refer|
        user_refer_item = {}
        user_refer_item[:id] = user_refer.id
        user_refer_item[:ref_type] = user_refer.ref_type
        user_refer_item[:number] = user_refer.number
        user_refer_item[:business_id] = user_refer.business_id
        user_info_item[:practi_refers_attributes] << user_refer_item
      end
      user_info_item[:practitioner_avails_attributes] = []
      # getting user availalibity
      user_info.practitioner_avails.each do |user_avail|
        user_avail_item = {}
        user_avail_item[:id] = user_avail.id
        user_avail_item[:business_id] = user_avail.business_id
        user_avail_item[:business_name] = user_avail.business_name
        user_avail_item[:days_attributes] = []
        user_avail.days.each do |day|
          day_item = {}
          day_item[:id] = day.id
          day_item[:day_name] = day.day_name
          day_item[:start_hr] = day.start_hr.nil? ? "9" : day.start_hr
          day_item[:start_min] = day.start_min
          day_item[:end_hr] = day.end_hr
          day_item[:end_min] = day.end_min
          day_item[:is_selected] = day.is_selected
          day_item[:practitioner_breaks_attributes] = []
          # adding breaks day wise
          day.practitioner_breaks.each do |user_break|
            user_break_item = {}
            user_break_item[:id] = user_break.id
            user_break_item[:start_hr] = user_break.start_hr
            user_break_item[:start_min] = user_break.start_min
            user_break_item[:end_hr] = user_break.end_hr
            user_break_item[:end_min] = user_break.end_min
            day_item[:practitioner_breaks_attributes] << user_break_item
          end
          user_avail_item[:days_attributes] << day_item
        end
        user_info_item[:practitioner_avails_attributes] << user_avail_item
      end
      result[:practi_info_attributes] = user_info_item
    else
      #  ADDING USER INFO NEW OBJECT
      user_info = user.build_practi_info
      user_refer = user_info.practi_refers.build
      user_info_item = {}
      user_info_item[:designation] = user_info.designation
      user_info_item[:desc] = user_info.desc
      user_info_item[:default_type] = user_info.default_type
      user_info_item[:notify_by] = user_info.notify_by
      user_info_item[:cancel_time] = user_info.cancel_time
      user_info_item[:is_online] = user_info.is_online
      user_info_item[:appointment_services] = []
      user_info_item[:allow_external_calendar] = user_info.allow_external_calendar

      user_info_item[:practi_refers_attributes] = []
      #  ADDING PRACTI REFERS
      user_refer_item = {}
      user_refer_item[:ref_type] = user_refer.ref_type
      user_refer_item[:number] = user_refer.number
      user_refer_item[:business_id] = user_refer.business_id
      user_info_item[:practi_refers_attributes] << user_refer_item
      #  END
      user_info_item[:practitioner_avails_attributes] = []
      result[:practi_info_attributes] = user_info_item

    end
    # end
    return result
  end

  def manage_deleted_params(params)
    params[:user][:practi_info_attributes][:practitioner_avails_attributes].each do |user_avail|
      unless user_avail[:id].nil?
        # user_avail_obj  = PractitionerAvail.find(user_avail["id"])
        user_avail[:days_attributes].each do |day|
          day_breaks = Day.find(day["id"]).practitioner_breaks.ids
          coming_day_breaks_id = []
          day[:practitioner_breaks_attributes].each do |day_break|
            coming_day_breaks_id << day_break[:id]
          end unless day[:practitioner_breaks_attributes].nil?
          day[:practitioner_breaks_attributes] = [] if day[:practitioner_breaks_attributes].nil?
          deleteable_breaks_id = day_breaks - coming_day_breaks_id
          deleteable_breaks_id.each do |bk_id|
            p_bk = PractitionerBreak.find(bk_id)
            item = {}
            item[:id] = p_bk.id
            item[:_destroy] = true
            day[:practitioner_breaks_attributes] << item
          end
        end
      end
    end
    # Deleting practi_refer adding code by moanoranjan
    all_practi_refers_ids = @user.practi_refers.pluck("id")
    unless  params[:user][:practi_info_attributes][:practi_refers_attributes].nil?
      coming_refer_ids = params[:user][:practi_info_attributes][:practi_refers_attributes].map{|k| k['id']}
      deletable_refer_ids = all_practi_refers_ids - coming_refer_ids
    else
      params[:user][:practi_info_attributes][:practi_refers_attributes] = []
      deletable_refer_ids = all_practi_refers_ids
    end
    deletable_refer_ids.each do |refer_id|
      item = {id: refer_id , :_destroy=> true}
      params[:user][:practi_info_attributes][:practi_refers_attributes] << item
    end
  end
end
