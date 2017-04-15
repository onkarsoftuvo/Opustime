class CreateDocumentAndPrintings < ActiveRecord::Migration
  def change
    create_table :document_and_printings do |t|
      t.string :logo_height
      t.string :in_page_size
      t.string :in_top_margin
      t.string :as_title
      t.string :l_space_un_logo
      t.string :l_top_margin
      t.string :l_bottom_margin
      t.string :l_bleft_margin
      t.string :l_right_margin
      t.string :tn_page_size
      t.string :tn_top_margin
      t.boolean :l_display_logo, default: true
      t.boolean :tn_display_logo, default: true
      t.boolean :hide_us_cb , default: false
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
