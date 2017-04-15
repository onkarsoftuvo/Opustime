class RecallPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner
  serialize :recall_add
  serialize :recall_edit
  serialize :recall_delete
  serialize :recall_addpnt
  serialize :recall_editpnt
  serialize :recall_deletepnt
  serialize :recall_markpnt

  scope :specific_attr , ->{ select('recall_add , recall_edit , recall_delete , recall_addpnt , recall_editpnt , recall_deletepnt , recall_markpnt  ')}

end
