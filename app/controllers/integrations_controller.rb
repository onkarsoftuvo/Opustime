class IntegrationsController < ApplicationController
  respond_to :json
  before_filter :authorize 
  before_action :find_company_by_sub_domain , :only =>[:mail_chimp_integration , :get_mail_chimp_info , :save_fb_page_id , :facebook_pages_list]
  
  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  before_filter :check_authorization , :only =>[:mail_chimp_integration , :get_mail_chimp_info , :save_fb_page_id , :facebook_pages_list]

  def mail_chimp_integration
    result = {flag: true}
    mailchimp = Mailchimp::API.new(params[:mailchimp_key]) rescue nil 
    unless mailchimp.nil?
      listId = get_list_id(mailchimp , params[:list_name])
      unless listId.empty?
        MailchimpWorker.perform_async(params[:mailchimp_key] , listId , @company.id)
      else 
        result[:The_list] = " could not be found. A valid list is required. A connection has NOT been made."
        result[:flag] = false  
      end  
    else
      result[:the_api_key]  = " is not valid. A connection has NOT been made."
      result[:flag] = false
    end
    unless @company.mail_chimp_info.nil?
      @company.mail_chimp_info.update_attributes(key: params[:mailchimp_key] , list_name: params[:list_name] , :is_valid => result[:flag] , list_id: (listId.empty? ? nil : listId) )            
    else
      @company.create_mail_chimp_info(key: params[:mailchimp_key] , list_name: params[:list_name] , :is_valid => result[:flag], list_id: (listId.empty? ? nil : listId) )          
    end
    render :json => result
    
  end
  
  def get_mail_chimp_info
    result = {}
    mailchimp_info = @company.mail_chimp_info
    unless mailchimp_info.nil?
      result[:key] = mailchimp_info.key
      result[:list_name] = mailchimp_info.list_name
      result[:flag] = mailchimp_info.is_valid    
    end 
    render :json => {:mail_chimp_info => result }
  end
  
  def facebook_integration
    result = {flag: true}
    render :json=> result
  end
  
  def save_fb_page_id
    result = { flag: false }
    if params[:fb_page_id].present?
      @company.facebook_pages.create(page_id: params[:fb_page_id])
      result = { flag: true }    
    end
    render :json=> result
  end
  
  def remove_fb_page_id
    result = { flag: false }
    if params[:fb_page_id].present?
      fb_page = FacebookPage.find_by_page_id(params[:fb_page_id])
      fb_page.destroy
      result = { flag: true }    
    end
    render :json=> result  
  end 
  
  def facebook_pages_list
    result = []
    @company.facebook_pages.each do |page| 
      result << page.page_id 
    end
    render :json => result
  end
  
  private

  def check_authorization
    authorize! :manage , :integration
  end

  def get_list_id(mailchimp , list_name)
    listId = ""
    lists = mailchimp.lists.list["data"] rescue nil
    lists.each do |list|
      if list["name"].casecmp(list_name) == 0
        listId = list["id"]
      end 
    end unless lists.nil?
    return listId
  end
  
   
end
