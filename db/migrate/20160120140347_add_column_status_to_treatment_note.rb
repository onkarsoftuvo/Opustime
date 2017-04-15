class AddColumnStatusToTreatmentNote < ActiveRecord::Migration
  def change
    add_column :treatment_notes, :status, :boolean , default: true
  end
end
