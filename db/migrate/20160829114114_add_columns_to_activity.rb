class AddColumnsToActivity < ActiveRecord::Migration
  def change
  	add_reference :activities , :business , :index=> true
  end
end
