class AdjustColumnsToTreatmentNote < ActiveRecord::Migration
  def change
    add_column :treatment_notes , :title , :string , :limit=> 100
    remove_column :treatment_notes , :template_id 
  end
end
