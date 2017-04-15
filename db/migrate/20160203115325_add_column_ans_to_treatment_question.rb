class AddColumnAnsToTreatmentQuestion < ActiveRecord::Migration
  def change
    add_column :treatment_questions , :ans , :string , limit: 50
  end
end
