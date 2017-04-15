class CreateDashboardPermissions < ActiveRecord::Migration
  def change
    create_table :dashboard_permissions do |t|
      t.text :dashboard_top
      t.text :dashboard_report
      t.text :dashboard_appnt
      t.text :dashboard_activity
      t.text :dashboard_chartpracti
      t.text :dashboard_chartpracti
      t.text :dashboard_chartproduct
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
