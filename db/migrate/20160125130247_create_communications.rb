class CreateCommunications < ActiveRecord::Migration
  def change
    create_table :communications do |t|
      t.datetime :comm_time , null:false
      t.string :type , limit:25
      t.string :category , limit:25
      t.string :direction , limit:25
      t.string :to , limit:75
      t.string :from , limit:75
      t.text :message
      t.boolean :send_status , default: false
      t.string :link_item , limit:25
      t.string :link_id , limit:25
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
