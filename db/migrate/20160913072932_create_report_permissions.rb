class CreateReportPermissions < ActiveRecord::Migration
  def change
    create_table :report_permissions do |t|
      t.text :report_apnt
      t.text :report_missapnt
      t.text :report_upbday
      t.text :report_pupapnt
      t.text :report_totinvoice
      t.text :report_dpay
      t.text :report_pmt
      t.text :report_invoice
      t.text :report_revenue
      t.text :report_prarevenue
      t.text :report_expense
      t.text :report_recall
      t.text :report_refersrc
      t.text :report_pntmarket
      t.text :report_apntmarket

      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
