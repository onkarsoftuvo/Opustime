class CreateSmsTemplates < ActiveRecord::Migration
  def change
    create_table :sms_templates do |t|
      t.string :template_name
      t.text :body
      t.text :addition_tabs
      t.references :company, index: true, foreign_key: true
      t.boolean :status , default: true

      t.timestamps null: false
    end
  end
end
