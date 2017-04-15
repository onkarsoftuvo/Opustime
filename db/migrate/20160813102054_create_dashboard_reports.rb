class CreateDashboardReports < ActiveRecord::Migration
  def change
    create_table :dashboard_reports do |t|
      t.references :company, index: true, foreign_key: true
      t.boolean :appnt , :default => false
      t.boolean :doctor , :default => false
      t.boolean :revenue , :default => false
      t.boolean :refer_type , :default => false
      t.boolean :daily_report , :default => false

      t.timestamps null: false
    end
  end
end
