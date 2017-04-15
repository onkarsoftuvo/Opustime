class AddColumnsToOwner < ActiveRecord::Migration
  def change
    add_column :owners , :password_digest , :string
    add_column :owners , :remember_digest , :string
    add_column :owners , :password_reset_token , :string
    add_column :owners , :password_reset_sent_at , :datetime
  end
end
