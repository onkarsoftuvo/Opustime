class AddAdditionTabToLetterTemplate < ActiveRecord::Migration
  def change
    add_column :letter_templates, :addition_tabs, :text 
  end
end
