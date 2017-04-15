class AddColumnThemeToAccount < ActiveRecord::Migration
  def change
  	add_column :accounts , :theme_name  ,:string
  end
end
