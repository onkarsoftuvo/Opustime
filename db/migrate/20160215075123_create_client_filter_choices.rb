class CreateClientFilterChoices < ActiveRecord::Migration
  def change
    create_table :client_filter_choices do |t|
      t.boolean :appointment
      t.boolean :invoice
      t.boolean :payment
      t.boolean :attached_file
      t.boolean :letter
      t.boolean :communication
      t.boolean :recall
      t.boolean :treatment_note
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
