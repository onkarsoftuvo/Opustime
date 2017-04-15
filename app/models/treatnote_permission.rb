class TreatnotePermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner
  serialize :treatnote_view, JSON
  serialize :treatnote_viewall, JSON
  serialize :edit_own, JSON
  serialize :treatnote_delete, JSON

  scope :specific_attr , ->{ select('treatnote_view , treatnote_viewall , edit_own , treatnote_delete ')}
end
