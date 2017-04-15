class Export < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  belongs_to :company

  has_attached_file :doc ,
               :url => "settings/company/:company_id/export/:extension/:id/:basename.:extension" ,
               :path => "public/attachments/companies/:company_id/export/:extension/:id/:basename.:extension"

    validates_attachment_size :doc, :less_than => 10.megabytes    
    validates_attachment_presence :doc 
    validates_attachment_content_type :doc, :content_type => ["text/csv" , "application/zip"]

  Paperclip.interpolates :company_id do |attachment, style|
    attachment.instance.company_id
  end
  def get_file_size
    number_to_human_size(self.doc_file_size) 
  end

  def generate_custom_name(flag = false)
	export_dt = self.created_at.strftime("%Y%m%d")
	st_date = self.ex_date_range.split("-")[0].split("/").reverse.join("")
	end_date = self.ex_date_range.split("-")[1].split("/").reverse.join("")
	obj_name = self.ex_type.split("(")[0].capitalize.to_s+"s"
	file_size =  self.get_file_size
	doc_name = obj_name.to_s + "-OpusTime-" + export_dt + "-From" + st_date + "-To" + end_date+ (flag == true ? ".zip(#{file_size})" : ".csv(#{file_size})")
	return doc_name
  end


end
