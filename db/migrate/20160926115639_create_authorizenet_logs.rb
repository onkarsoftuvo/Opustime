class CreateAuthorizenetLogs < ActiveRecord::Migration
  def change
    create_table :authorizenet_logs do |t|
      t.references :company, :index => true
      # it may transaction_id, subscription_id or customer_profile_id
      t.string :response_id
      t.string :action_name
      t.string :response_code
      t.text :response_message
      t.boolean :error_status
      t.timestamps null: false
    end
  end
end
