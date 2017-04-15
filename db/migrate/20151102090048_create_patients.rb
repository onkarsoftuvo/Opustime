class CreatePatients < ActiveRecord::Migration
  def change
    create_table :patients do |t|
      t.string :title
      t.string :first_name
      t.string :last_name
      t.integer :dob_day
      t.string :dob_month
      t.integer :dob_year
      t.string :gender
      t.text :relationship
      t.string :phone_list
      t.string :email
      t.string :reminder_type
      t.boolean :sms_marketing , default:false
      t.text :address
      t.string :country
      t.string :state
      t.string :city
      t.integer :postal_code
      t.string :concession_type
      t.text :invoice_to
      t.string :invoice_email
      t.text :invoice_extra_info
      t.string :occupation
      t.string :emergency_contact
      t.string :medicare_number
      t.string :reference_number
      t.string :refer_doctor
      t.text :notes
      t.string :referral_type
      t.string :referrer
      t.string :extra_info
      t.text :medical_alert
      t.boolean :status , default:true
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
