class AddColumnCreatedbyToTreatmentNote < ActiveRecord::Migration
  def change
    add_column :treatment_notes ,  :created_by_id , :string , :limit=> 25 , :null=> false 
  end
end
