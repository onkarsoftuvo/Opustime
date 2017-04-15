class CreateAdminPermissions < ActiveRecord::Migration
  def change
    create_table :admin_permissions do |t|
      t.text :business_report
      t.text :financial_report
      t.boolean :trial_user
      t.text :notification
      t.text :subscription
      t.text :sms
      t.text :others
      t.boolean :permission
      t.boolean :logs
      t.references :user_role, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
