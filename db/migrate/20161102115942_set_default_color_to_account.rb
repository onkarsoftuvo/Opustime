class SetDefaultColorToAccount < ActiveRecord::Migration
  def change
    change_column :accounts , :theme_name  ,:string,  :default => "blue_theme"
  end
end
