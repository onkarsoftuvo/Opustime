class AddColumnListIdToMailChimpInfo < ActiveRecord::Migration
  def change
    add_column :mail_chimp_infos, :list_id, :string
  end
end
