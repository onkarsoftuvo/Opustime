class CreateCommunicationPermissions < ActiveRecord::Migration
  def change
    create_table :communication_permissions do |t|

      t.text :communication_view
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
