class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password
      t.string :country
      t.timestamp :time_zone
      t.string :attendees , default: "patients", null: false
      t.boolean :note_letter , default: false , null: false
      t.boolean :show_finance , default: false , null: false
      t.boolean :show_attachment , default: false , null: false
      t.string :communication_email
      t.text :calendar_setting
      t.boolean :multi_appointment, default: false , null: false
      t.boolean :show_time_indicator , default: true , null: false
      t.string :patient_name_by , default: "First Name" , null: false

      t.timestamps null: false
    end
  end
end
