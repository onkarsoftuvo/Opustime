class CreateGeneralTabs < ActiveRecord::Migration
  def change
    create_table :general_tabs do |t|
      t.string :CurrentDate , :default=> "General.CurrentDate" , :limit=> 30

      t.timestamps null: false
    end
  end
end
