class CreateSmsPlans < ActiveRecord::Migration
  def change
    create_table :sms_plans do |t|
      t.integer :amount
      t.integer :no_sms
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
