class CreateQboAuthentications < ActiveRecord::Migration
  def change
    create_table :qbo_authentications do |t|
      t.references :company, index: true, foreign_key: true
      t.text :token
      t.text :secret

      t.timestamps null: false
    end
  end
end
