class QboLogSerializer < ActiveModel::Serializer
  attributes :id, :loggable_id, :loggable_type, :action_name, :message, :status, :created_at
  include Opustime::Utility

  ## override created_at attribute
  def created_at
    timeZone = timeZone_lookup(object.company.account.time_zone)
    object.created_at.utc.in_time_zone(timeZone).strftime('%A, %d %b %Y %l:%M %p')
  end
end
