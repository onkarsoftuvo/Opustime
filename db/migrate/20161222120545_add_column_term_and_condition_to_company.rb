class AddColumnTermAndConditionToCompany < ActiveRecord::Migration
  def change
    add_column :companies , :terms , :boolean , :default => false
  end
end
