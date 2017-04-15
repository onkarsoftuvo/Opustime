class CreateAttempts < ActiveRecord::Migration
  def change
    create_table :attempts do |t|
      t.string :ip_address
      t.datetime :login_fail_date
      t.integer :login_fail_count, :default => 0

      t.timestamps null: false
    end
  end
end
