class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :country
      t.string :time_zone
      t.string :attendees
      t.boolean :note_letter
      t.boolean :show_finance
      t.boolean :show_attachment
      t.string :communication_email
      t.text :calendar_setting
      t.boolean :multi_appointment
      t.boolean :show_time_indicator
      t.string :patient_name_by
      t.string :company_name
      t.string :password_digest
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
