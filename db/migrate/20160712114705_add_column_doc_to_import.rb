class AddColumnDocToImport < ActiveRecord::Migration
	def self.up
	    change_table :imports do |t|
	      t.attachment :doc
	    end
	end

	def self.down
		remove_attachment :imports, :doc
    end 

end
