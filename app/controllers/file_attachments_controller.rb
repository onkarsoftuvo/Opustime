class FileAttachmentsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:upload]
  before_action :find_patient , :only => [:upload]
  before_action :find_attachment , :only => [:update , :destroy , :edit]
  before_filter :set_current_user , :only => [:upload ]


  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def upload
    authorize! :upload , FileAttachment
    unless @patient.nil?
      attachment = @patient.file_attachments.new(avatar: params[:file])
      if attachment.valid?
        attachment.save
        result = {flag: true , id: attachment.id , url: attachment.avatar.url }
        render :json=> result
      else
        attachment = FileAttachment.new
        attachment.errors.add(:attachment, 'Only PDF, EXCEL, WORD or TEXT files are allowed !')
        show_error_json(attachment.errors.messages)

      end
    else 
      file_upload =  FileAttachment.new
      file_upload.errors.add(:patient ,'not found !')
    end    
  end
  
  def show
    
  end
  
  def view_name
    
  end
  
  def edit
    result = {}
    result[:id] = @file.id
    result[:file_name] = @file.avatar_file_name
    result[:description] = @file.description 
    render :json => result 
  end
  
  def update
    @file.update_attributes(:description => params[:description] )
    if @file.valid?
      result = {flag: true , id: @file.id }
      render :json=> result
    else
      show_error_json(@file.errors.messages)
    end
  end
  
  def destroy
    @file.destroy
    render :json=> {flag:true} 
  end
  
  def set_current_user
    FileAttachment.current = current_user
  end
  
  private 
  
  # def file_attachment_params
    # params.require(:file_attachment).permit(:avatar)
  # end
  
  def find_patient
    @patient = Patient.find(params[:id]) rescue nil
  end
  
  def find_attachment
    @file = FileAttachment.find(params[:id])
  end
  
end
