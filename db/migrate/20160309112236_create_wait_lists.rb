class CreateWaitLists < ActiveRecord::Migration
  def change
    create_table :wait_lists do |t|
      t.date :remove_on
      t.text :availability
      t.string :options
      t.text :extra_info
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
