class Import < ActiveRecord::Base
  belongs_to :company
	belongs_to :user
  serialize :imported_obj_ids , Array

  has_attached_file :doc ,
               :url => "settings/company/:company_idimport/:extension/:id/:basename.:extension" ,
               :path => "public/attachments/companies/:company_id/import/:extension/:id/:basename.:extension"

	validates_attachment_presence :doc 
	validates_attachment_content_type :doc, :content_type => ["text/csv"]
	Paperclip.interpolates :company_id do |attachment, style|
		attachment.instance.company_id
	end

	def total_records
		doc_file = self.doc
		unless doc_file.nil?
			spreadsheet = Roo::Spreadsheet.open(doc_file.url)
		    no = ((spreadsheet.last_row) -1) rescue 0
		    return no
		end
	end

	def get_import_type
		self.import_type.to_s+"(#{self.total_records})"
	end

	def attached_doc_column_names
    	doc_file = self.doc
    	header = []
		unless doc_file.nil?
			spreadsheet = Roo::Spreadsheet.open(doc_file.url)
		    no = ((spreadsheet.last_row) -1) rescue nil
		    unless no.nil?
		    	header = spreadsheet.row(1)	
		    end
		end 		
		return header
	end

	def delete_associated_records
		if self.import_type == "patient"
			obj_ids = self.imported_obj_ids
		    obj_ids.each do |p_id|
		      record = Patient.find_by_id(p_id)
		      unless record.nil?
		        record.destroy
		      end
		    end

		elsif self.import_type == "contact"
			obj_ids = self.imported_obj_ids
		    obj_ids.each do |p_id|
		      record = Contact.find_by_id(p_id)
		      unless record.nil?
		        record.destroy
		      end
		    end

		elsif self.import_type == "product"
			obj_ids = self.imported_obj_ids
		    obj_ids.each do |p_id|
		      record = Product.find_by_id(p_id)
		      unless record.nil?
		        record.destroy
		      end
		    end

		elsif self.import_type == "billableItem"
			obj_ids = self.imported_obj_ids
		    obj_ids.each do |p_id|
		      record = BillableItem.find_by_id(p_id)
		      unless record.nil?
		        record.destroy
		      end
		    end
		 end   
	end


end
