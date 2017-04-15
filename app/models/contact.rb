class Contact < ActiveRecord::Base
  include IdentificationKey

  belongs_to :company
  has_many :contact_nos, :dependent=> :destroy
  
  accepts_nested_attributes_for :contact_nos , :allow_destroy => true
  
  has_many :patients_contact , :dependent=> :destroy
  has_many :patients, :through => :patients_contact, :dependent => :destroy
  # has_many :sms_logs , :dependent => :destroy
  has_many :sms_logs, :as => :object , :dependent => :destroy
  has_many :patients, :as => :referral, :dependent => :destroy
  
  validates :contact_type , inclusion: { in: ["Standard" ,"standard" , "Doctor","doctor", "3rd Party Payer", "3rd party Payer"]}

  #serialize :phone_list , Array
  
  validates :first_name , presence: true 
  validates :provider_number , :presence=> true , :if=> Proc.new{|a| a.contact_type=="doctor"}
  
  # validates :post_code , zipcode: { country_code_attribute: :country }
  validates :post_code , zipcode: { country_code_attribute: :country }, :allow_blank => true
  validates :email, :format=> {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i} , :on=>[:create , :update] , :allow_nil => true , :allow_blank => true
     
  scope :specific_attributes , ->{ select("id , contact_type , title , first_name , last_name , preffered_name , occupation , company_name , provider_number , phone_list, email , address, city , state, post_code, country, notes")}
  scope :active_contact, ->{ where(status: true)}

  before_create :set_contact_type

  self.per_page = 30
  
  def full_name
    self.title.to_s.capitalize + ((self.title.to_s.casecmp('master') == 0 || self.title.to_s.blank?) ? ' ':'. ') + (self.first_name.to_s + ' ' +  self.last_name.to_s).split.map(&:capitalize).join(' ')
  end

  def get_state_country_name
    unless self.country.nil?
      country = ISO3166::Country.new(self.country)
      country_name = country.try(:name)
      unless self.state.nil?
        state_code = self.try(:state).split("-")[1]
        state_name = country.states[state_code]["name"] unless state_code.nil?
        return state_name , country_name
      else
        return '' , country_name
      end
    else
      return '' , ''
    end
  end

  def get_mobile_no_type_wise(m_type)
    contact = self.contact_nos.where(["contact_type = ? ", m_type])
    cont_no = (contact.length > 0 ? contact.first.try(:contact_number).to_s : " ")
    return cont_no
  end

  def get_contacts(index)
    contact = self.contact_nos[index]
    contact_no = contact.try(:contact_number)
    return contact_no
  end

  def get_primary_contact( num= nil)
    number = nil
    contact_list = self.contact_nos.map(&:contact_number)
    sms_log = self.sms_logs.last

    if num.nil?
      unless sms_log.nil? 
        sms_from_no = sms_log.try(:contact_from)
        sms_from =  contact_list.try(:first)
        contact_list.compact.map{|k| sms_from = k if sms_from_no.include?k }
        sms_to = sms_log.try(:contact_to) 
        
        if contact_list.include? sms_from
          number = sms_from
        elsif contact_list.include? sms_to
          number = sms_to
        else
          number = contact_list.length > 0 ? contact_list.first : nil
        end
      else
        number = contact_list.length > 0 ? contact_list.first : nil
      end
    else
      number = num
    end
    number = number.phony_formatted(format: :international, spaces: '-') unless number.nil?
    return number
  end

  def next_contact
    comp = self.company
    contact_ids = comp.contacts.order("created_at desc").active_contact.ids
    ele_index = contact_ids.index(self.id)
    next_elem = contact_ids.at(ele_index + 1)
    return next_elem
  end
  
  def prev_contact
    comp = self.company
    contact_ids = comp.contacts.order("created_at desc").active_contact.ids
    ele_index = contact_ids.index(self.id)
    prev = ele_index - 1
    prev_elem = (prev<0 ? nil : contact_ids.at(prev))
    return prev_elem
  end

  def get_previous_conversations(num)
    result = []
    comp = self.company
    mob_no = self.get_primary_contact(num).phony_formatted(format: :international, spaces: '').phony_normalized
    sms_logs = SmsLog.where(["(contact_to LIKE ? OR contact_from LIKE ?) AND company_id = ? AND object_id = ?" ,"%#{mob_no}%" , "%#{mob_no}%" , comp.id , self.id ]).order("created_at desc")
    sms_logs.each_with_index do |log, index|
      item = {}
      item[:sms_body] = log.sms_text
      item[:sent_time] = log.formatted_delivered_time
      item[:direction] = log.status == "Received" ? "inbound" : "outbound"  
      item[:status] = log.status
      result << item
    end

    return result

  end

  private 
  def set_contact_type
    self.contact_type = "doctor" if self.contact_type.nil?
  end
  
end
