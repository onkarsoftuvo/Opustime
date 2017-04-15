class AddColumnIsValidToMailChimpInfo < ActiveRecord::Migration
  def change
    add_column :mail_chimp_infos, :is_valid, :boolean , default: false
  end
end
