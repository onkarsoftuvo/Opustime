class ReportPermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :report_apnt
  serialize :report_missapnt
  serialize :report_upbday
  serialize :report_pupapnt
  serialize :report_totinvoice
  serialize :report_dpay
  serialize :report_pmt
  serialize :report_invoice
  serialize :report_revenue
  serialize :report_prarevenue
  serialize :report_expense
  serialize :report_recall
  serialize :report_refersrc
  serialize :report_pntmarket
  serialize :report_apntmarket

  scope :specific_attr , ->{ select('report_apnt , report_missapnt , report_upbday ,
report_pupapnt , report_totinvoice , report_dpay ,report_pmt , report_invoice ,
  report_revenue , report_prarevenue , report_expense , report_recall , report_refersrc , report_pntmarket , report_apntmarket ')}
end
