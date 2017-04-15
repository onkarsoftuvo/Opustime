class NotificationSerializer < ActiveModel::Serializer
  include Opustime::Utility
  attributes :id, :initiatable_id, :initiatable_type, :targetable_id, :targetable_type, :payload, :message, :is_read, :is_open, :created_at

  # override created_at attribute
  def created_at
    object.created_at.strftime('%A, %d %b %Y %l:%M %p')
  end

  # override payload attribute
  def payload
    payload_info = object.payload
    payload_info.each do |key, val|
      payload_info[key] = val.phony_formatted(format: :international, spaces: '-') if key.to_s.eql?('sender_contact')
    end
    return payload_info
  end

end
