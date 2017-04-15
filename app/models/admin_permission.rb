class AdminPermission < ActiveRecord::Base
  belongs_to :user_role

  serialize :business_report , JSON
  serialize :financial_report , JSON
  serialize :notification , JSON
  serialize :subscription , JSON
  serialize :sms , JSON
  serialize :others , JSON

end
