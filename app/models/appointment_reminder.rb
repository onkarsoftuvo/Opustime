class AppointmentReminder < ActiveRecord::Base
  belongs_to :company
  
  # validates_format_of :ac_email_subject , :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i , :message=> " doesn't look like an email address"

  scope :specific_attributes , ->{ select('id, d_reminder_type, reminder_time, skip_weekends, reminder_period,
                apply_reminder_type_to_all, ac_email_subject, ac_email_content,
                ac_app_can_show, hide_address_show, reminder_email_subject,
                reminder_email_enabled, reminder_email_content, reminder_app_can_show,
                sms_enabled, sms_text, sms_app_can_show')}

  # after_update :update_system_cronjob
  #
  # def update_system_cronjob
  #   # rm_previous_changes = self.previous_changes
  #   unless (self.reminder_time_was).eql?(self.reminder_time)
  #     CronjobWorker.perform_async()
  #   end
  # end

  #  convert reminder time period into utc time
  def reminder_time_in_utc
    current_time = Time.now
    custom_time = DateTime.new(current_time.strftime('%Y').to_i , current_time.strftime('%m').to_i , current_time.strftime('%d').to_i , self.reminder_time.to_i , 0 , 0 , time_zone_offset)
    unless custom_time.nil?
      return custom_time.utc
      # return custom_time
    else
      return 0
    end
  end

  # Find offset according to timezone name

  def time_zone_offset
    tm_zone_name = self.company.try(:account).try(:time_zone)
    tm_zone_name = self.company.try(:time_zone) if tm_zone_name.nil?
    unless tm_zone_name.nil?
      unless tm_zone_name.eql?'UTC'
        offset = OpusTimezone.find_by(timezone_name: tm_zone_name).try(:offset)
        return offset
      else
        return +0000
      end
    else
      return +0000
    end


  end

end
