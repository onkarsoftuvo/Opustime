class OpustimeLogSerializer < ActiveModel::Serializer
  attributes :id, :class_name, :message, :trace, :params, :target_url, :user_info, :created_at
  include Opustime::Utility

  ## override created_at attribute
  def created_at
    if @instance_options[:log_level].to_s.eql?('user_logs')
      # get user timeZone
      timeZone = timeZone_lookup(@instance_options[:user].time_zone)
    else
      # get company timeZone
      timeZone = timeZone_lookup(@instance_options[:company].account.time_zone) rescue nil
    end
    object.created_at.utc.in_time_zone(timeZone).strftime('%A, %d %b %Y %l:%M %p')
  end
end
