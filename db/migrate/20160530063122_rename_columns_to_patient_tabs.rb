class RenameColumnsToPatientTabs < ActiveRecord::Migration
  def change
    rename_column :patient_tabs , :FullName , :full_name
    rename_column :patient_tabs , :Title , :title
    rename_column :patient_tabs , :FirstName , :first_name
    rename_column :patient_tabs , :LastName , :last_name
    rename_column :patient_tabs , :MobileNumber , :mobile_number
    rename_column :patient_tabs , :HomeNumber , :home_number
    rename_column :patient_tabs , :WorkNumber , :work_number
    rename_column :patient_tabs , :FaxNumber , :fax_number
    rename_column :patient_tabs , :OtherNumber , :other_number
    rename_column :patient_tabs , :Email , :email
    rename_column :patient_tabs , :Address , :address
    rename_column :patient_tabs , :City , :city
    rename_column :patient_tabs , :PostCode , :post_code
    rename_column :patient_tabs , :State , :state
    rename_column :patient_tabs , :Country , :country
    rename_column :patient_tabs , :DateOfBirth , :dob
    rename_column :patient_tabs , :Gender , :gender
    rename_column :patient_tabs , :Occupation , :occupation
    rename_column :patient_tabs , :EmergencyContact , :emergency_contact
    rename_column :patient_tabs , :ReferralSource , :referral_source
    rename_column :patient_tabs , :MedicareNumber , :medicare_number
    rename_column :patient_tabs , :OldReferenceId , :old_reference_id
    rename_column :patient_tabs , :IdentificationNumber , :id_number
    rename_column :patient_tabs , :Notes , :notes
    rename_column :patient_tabs , :FirstAppointmentDate , :first_appt_date 
    rename_column :patient_tabs , :FirstAppointmentTime , :first_appt_time
    rename_column :patient_tabs , :MostRecentAppointmentDate , :most_recent_appt_date
    rename_column :patient_tabs , :MostRecentAppointmentTime , :most_recent_appt_time
    rename_column :patient_tabs , :NextAppointmentDate , :next_appt_date
    rename_column :patient_tabs , :NextAppointmentTime , :next_appt_time
  end
end
