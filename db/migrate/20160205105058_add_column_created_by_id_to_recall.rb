class AddColumnCreatedByIdToRecall < ActiveRecord::Migration
  def change
    add_column :recalls , :created_by_id , :string
  end
end
