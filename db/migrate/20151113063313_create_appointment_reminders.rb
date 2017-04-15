class CreateAppointmentReminders < ActiveRecord::Migration
  def change
    create_table :appointment_reminders do |t|
      t.string :d_reminder_type
      t.string :reminder_time
      t.boolean :skip_weekends, default:false
      t.string :reminder_period
      t.boolean :apply_reminder_type_to_all, default:false
      t.string :ac_email_subject
      t.text :ac_email_content
      t.boolean :ac_app_can_show, default:false
      t.boolean :hide_address_show, default:false
      t.string :reminder_email_subject
      t.boolean :reminder_email_enabled, default:false
      t.text :reminder_email_content
      t.boolean :reminder_app_can_show, default:false
      t.boolean :sms_enabled, default:false
      t.text :sms_text
      t.boolean :sms_app_can_show, default:false
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
