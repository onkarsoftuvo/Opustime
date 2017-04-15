class RemoveAuthorizeAndAddNmiDetail < ActiveRecord::Migration
  def self.up
    remove_column :companies, :authorizenet_profile_id
    remove_column :companies, :authorizenet_payment_profile_id
    add_column :companies, :vault_id, :string
  end

  def self.down
    add_column :companies, :authorizenet_profile_id, :string
    add_column :companies, :authorizenet_payment_profile_id, :string
    remove_column :companies, :vault_id, :string
  end
end
