class CreateRecallPermissions < ActiveRecord::Migration
  def change
    create_table :recall_permissions do |t|
      t.text :recall_add
      t.text :recall_edit
      t.text :recall_delete
      t.text :recall_addpnt
      t.text :recall_editpnt
      t.text :recall_deletepnt
      t.text :recall_markpnt
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
