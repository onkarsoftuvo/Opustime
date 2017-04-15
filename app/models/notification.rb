class Notification < ActiveRecord::Base
  include ApplicationHelper
  serialize :payload, Hash
  belongs_to :initiatable, :polymorphic => true
  belongs_to :targetable, :polymorphic => true

  scope :total_unread_notifications, ->(user) { where(:targetable => user).where(:is_read => false).count }
  scope :user_notifications, ->(user, page_no) { where(:targetable => user).paginate(:page => page_no.to_i, :per_page => 10).order('created_at DESC') }
  scope :unread_notifications, ->(user) { where(:targetable => user) }


  def self.sms_notification(sms_log_id, company_id, sender_id=nil, sender_class, sms_text, contact_from)
    company = Company.find_by_id(company_id)
    sender = Notification.find_sender(sender_id, sender_class)
    # sender is nil if he is Anonymous user not in Opustime
    company.users.each do |user|
      notification = Notification.new(:initiatable => sender.present? ? sender : nil, :targetable => user, :message => sms_text, :payload => {:sms_log_id => sms_log_id, :send_by => sender.present? ? sender.full_name : 'Anonymous', :receive_by => user.full_name, :sender_type => sender.present? ? sender.class.to_s : 'Anonymous', :sender_contact => contact_from})
      notification.save
      channel = "/messages/private/#{user.id}"
      Notification.send_web_push(channel, {:message => notification.message, :count => Notification.total_unread_notifications(user), :payload => notification.payload}) if Rails.env.production?
    end
  end

  def self.find_sender(sender_id, sender_class)
    case sender_class.to_s
      when 'Patient'
        return Patient.find_by_id(sender_id)
      when 'Contact'
        return Contact.find_by_id(sender_id)
      when 'User'
        return User.find_by_id(sender_id)
      else
        return nil
    end
  end

  def self.send_web_push(channel, data)
    message = {:channel => channel, :data => data, :ext => {:auth_token => FAYE_TOKEN}}
    uri = URI.parse('http://localhost:9292/faye')
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(:message => message.to_json)
    return http.request(request)
  end


end
