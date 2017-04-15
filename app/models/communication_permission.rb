class CommunicationPermission < ActiveRecord::Base
  include PermissionFormat


  belongs_to :owner
  serialize :communication_view, JSON
  scope :specific_attr , ->{ select('communication_view')}
end
