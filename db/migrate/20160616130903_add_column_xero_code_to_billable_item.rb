class AddColumnXeroCodeToBillableItem < ActiveRecord::Migration
  def change
    add_column :billable_items , :xero_code , :string
  end
end
