class TransactionSerializer < ActiveModel::Serializer
  attributes :id,:company_id,:response_id,:response_code,:response_message,:error_status,:amount,:transaction_type,:created_at
  include Opustime::Utility

  ## override created_at attribute
  def created_at
    timeZone = timeZone_lookup(object.company.account.time_zone)
    object.created_at.utc.in_time_zone(timeZone).strftime('%A, %d %b %Y %l:%M %p')
  end
end
