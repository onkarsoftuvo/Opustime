class SmsLog < ActiveRecord::Base
  include PublicActivity::Model
  tracked owner: Proc.new { |controller, model| !(controller.try(:current_user).nil?) ? controller.current_user : nil },
          company: Proc.new { |controller, model| model.company ? model.company : nil }

  belongs_to :patient
  belongs_to :user
  belongs_to :contact
  belongs_to :company
  belongs_to :object, :polymorphic => true

  after_create :create_notifications


  def create_notifications
      Notification.sms_notification(id,company.id, object.try(:id), object.class.to_s, sms_text,contact_from) if self.status.eql?('Received')
  end


  def get_sender
    self.object
  end

  def find_concession_type_for_log
    patient = self.patient
    cs_name = nil
    unless patient.nil?
      cs_name = patient.concession.try(:name)
    end
    return cs_name
  end

  # Checking Is there  any Practitioner having this contact number

  def self.has_doctor(contact_from)
    User.find_by_phone(contact_from)
  end

  def self.doctor(id)
    User.find_by_id(id)
  end

  def get_company
    comp = self.patient.try(:company) unless self.patient.nil?
    comp = self.contact.try(:company) unless self.contact.nil?
    comp = self.user.try(:company) unless self.user.nil?
    return comp.try(:id)
  end

  def formatted_delivered_time
    time_diff = Time.diff(self.delivered_on, Time.now)
    if time_diff[:year] > 0 || time_diff[:month] > 0 || time_diff[:week] > 0 || time_diff[:day] > 0
      del_time = self.delivered_on.strftime("%d/%m/%Y")
    else
      if time_diff[:hour] > 0 && time_diff[:minute] > 0
        del_time = "#{time_diff[:hour]} hours #{time_diff[:minute]} minutes ago "
      else
        if time_diff[:hour] > 0
          del_time = "#{time_diff[:hour]} hours ago "
        elsif time_diff[:minute] > 1
          del_time = "#{time_diff[:minute]} minutes ago "
        else
          del_time = "1 minute ago"
        end
      end
    end
    return del_time
  end

  def create_activity_log(sender, receiver, accurate_no, msg_text)
    # "#{sender.full_name} has sent a msg to #{receiver.full_name} on (#{accurate_no}). Message is - #{msg_text}"
    data = {}
    unless receiver.nil?
      data[:sender_id] = sender.try(:id)
      data[:sender_name] = sender.try(:full_name)
      data[:receiver_id] = receiver.try(:id)
      data[:receiver_name] = receiver.try(:full_name)
      data[:dsg_no] = accurate_no
      data[:sms] = msg_text
    else
      data[:sender_id] = sender.try(:id)
      data[:sender_name] = sender.try(:full_name)
      data[:receiver_id] = receiver.try(:id)
      data[:receiver_name] = receiver.try(:full_name)
      data[:dsg_no] = accurate_no
      data[:sms] = msg_text
    end
    return data
  end

  def receive_activity_log(sender_person, sms_text, contact_from, obj_type=nil)
    data = {}
    unless sender_person.nil?
      data[:sender_id] = sender_person.id
      data[:sender_name] = sender_person.full_name
      data[:dsg_no] = contact_from
      data[:sms] = sms_text
      data[:obj_type] = obj_type
    else
      data[:sender_id] = nil
      data[:sender_name] = "Unknown"
      data[:dsg_no] = contact_from
      data[:sms] = sms_text
      data[:obj_type] = obj_type
    end

    return data

  end

  def self.to_csv(options = {})
    column_names = %w(S.no Customer_Name Outgoing_Sms_User Contact_Number Type Delivered_On Sms_Text Status )
    # column_names = ["PATIENT PRACTITIONER SERVICE_TYPE CONTACT_NO EMAIL_ADDRESS BUSINESS_LOCATION"]

    CSV.generate(options) do |csv|
      csv << column_names
      all.each_with_index do |log , index|
        data = []
        data << index + 1
        sender_name = log.get_sender.try(:full_name)
        data << (sender_name.nil? ? "Unknown" : sender_name).to_s.gsub(' ','')
        data << (log.user.try(:full_name_with_title)).to_s.gsub(' ','')
        data << log.contact_to
        data << log.sms_type
        data << log.delivered_on
        data << log.sms_text
        data << log.status
        csv << data
      end
    end
  end

end
