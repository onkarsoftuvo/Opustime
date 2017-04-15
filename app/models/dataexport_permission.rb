class DataexportPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :dataexport_prod
  serialize :dataexport_invoice
  serialize :dataexport_pmt
  serialize :dataexport_expns
  serialize :dataexport_allexprt

  scope :specific_attr , ->{ select('dataexport_prod , dataexport_invoice , dataexport_pmt , dataexport_expns , dataexport_allexprt ')}
end
