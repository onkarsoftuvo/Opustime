class CreateCancelSubscriptions < ActiveRecord::Migration
  def change
    create_table :cancel_subscriptions do |t|
      t.references :company,:index=>true
      t.text :reason
      t.text :description
      t.timestamps null: false
    end
  end
end
