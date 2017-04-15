class CreateDataexportPermissions < ActiveRecord::Migration
  def change
    create_table :dataexport_permissions do |t|
      t.text :dataexport_prod
      t.text :dataexport_invoice
      t.text :dataexport_pmt
      t.text :dataexport_expns
      t.text :dataexport_allexprt
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
