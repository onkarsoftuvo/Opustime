class MailchimpWorker
  include Sidekiq::Worker
  sidekiq_options retry: true
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*25, name: 'mail_chimp_worker'}
    
  def perform(api_key , listId , comp_id)
    if lock.acquire!
      begin
        mailchimp = Mailchimp::API.new(api_key)
        subscribers = get_subscriber_lists(comp_id)
        mailchimp.lists.batch_subscribe(listId, subscribers, false, true, false)
      ensure
        lock.release!
      end
    end
  end
  
  
  private 
  
  def get_subscriber_lists(comp_id)
    company = Company.find_by_id(comp_id)
    patients = []
    patients = company.patients.active_patient unless company.nil?   
    subs_users = []
    patients.each do |patient|
      item = {}
      item[:EMAIL] = {"email"=>patient.email} 
      item[:EMAIL_TYPE] = "html"
      merge_item = {}
      merge_item[:FNAME] = patient.first_name
      merge_item[:LNAME] = patient.last_name
      merge_item[:TITLE] = patient.title
      merge_item[:GENDER] = patient.gender
      merge_item[:DOB] = patient.dob
      merge_item[:POSTAL_CODE] = patient.postal_code
      merge_item[:LAST_APPOINTMENT_DATE] = patient.appointments.order("created_at desc ").first.appnt_date.strftime("%Y-%m-%d") rescue nil
      merge_item[:LAST_BUSINESS_VISITED] = patient.appointments.order("created_at desc ").first.business.try(:name) rescue nil
      merge_item[:LAST_PRACTITIONER_SEEN] = patient.appointments.order("created_at desc ").first.user.try(:full_name_with_title) rescue nil
      item["merge_vars"] = merge_item
      subs_users << item 
    end
    return subs_users 
  end
  
end