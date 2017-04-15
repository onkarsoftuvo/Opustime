class CreateUserRolesOwners < ActiveRecord::Migration
  def change
    create_table :user_roles_owners do |t|
      t.references :owner, index: true, foreign_key: true
      t.references :user_role, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
