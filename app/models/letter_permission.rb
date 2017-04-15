class LetterPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :latter_viewown , JSON
  serialize :letter_viewall , JSON
  serialize :letter_delete , JSON

  scope :specific_attr , ->{ select('latter_viewown , letter_viewall , letter_delete')}
end
