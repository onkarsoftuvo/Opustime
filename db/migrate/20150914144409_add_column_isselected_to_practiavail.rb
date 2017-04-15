class AddColumnIsselectedToPractiavail < ActiveRecord::Migration
  def change
    add_column :practi_avails , :is_selected, :boolean , :deafult=> false
  end
end
