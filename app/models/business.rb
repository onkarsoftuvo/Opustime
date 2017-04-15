class Business < ActiveRecord::Base
  # include ValidatesZipcode
  # serialize :address , JSON
  # serialize :reg_info , JSON
  
  # attr_accessible  :name , :address , :reg_name , :reg_number , :web_url , :contact_info , :online_booking , :city, :state, :pin_code, :country 
  
  belongs_to :company 
  
  has_and_belongs_to_many :practi_infos , :dependent=> :destroy
  
  has_many :practi_avails , :dependent=> :destroy
  attr_accessor :owner_name
  
  validates_presence_of :name , :on=>[:create , :update]
  scope :head, ->{ where(:business_type=> BUSINESS_TYPE[1] )}
  
  validates :pin_code , zipcode: { country_code_attribute: :country }, :allow_blank => true
  
  has_many :appointments_businesses , :dependent=> :destroy
  has_many :appointments , :through=> :appointments_businesses    
  
  has_many :availabilities_businesses , :dependent => :destroy
  has_many :availabilities , :through=> :availabilities_businesses ,  :dependent => :destroy
  
  has_many :wait_lists_businesses , :dependent=> :destroy
  has_many :wait_lists , :through=> :wait_lists_businesses ,:dependent=> :destroy
  
  has_many :businesses_invoices ,  :dependent => :destroy
  has_many :invoices , :through=> :businesses_invoices ,  :dependent => :destroy
  
  has_many :businesses_payments , :dependent=> :destroy , :inverse_of=> :business
  has_many :payments , :through=> :businesses_payments , :dependent=> :destroy

  has_many :businesses_expenses , :dependent=> :destroy
  has_many :expenses , :through=> :businesses_expenses , :dependent=> :destroy

# later validations   
  # validates_associated :company , presence: true 
  validates :web_url, :presence => {:message => 'cannot be blank.'}, :format => {with: URI::regexp(%w(http https)) , :message=> "is invalid. http/https is required !"} , allow_nil: true
  # validates :pin_code, zipcode: { country_code: :country }

#  ending here --------   
#   validates :name , :address , :contact_info , :city , :state , :pin_code , :country , :reg_name , :reg_number , presence: true ,  :if => "online_booking== true"
#   validates :web_url, :presence => {:message => 'cannot be blank.'}, :format => {with: URI::regexp(%w(http https)) , :message=> "is invalid. http/https is required !"} ,  :if => "online_booking== true"
    
  def full_address
    busi_address = self.address
    busi_city = self.city
    country =  self.country.nil? ? nil : ISO3166::Country.new(self.country)
    unless self.state.nil?
      unless country.nil?
        state = country.states[self.state.split("-")[1]]["name"]
      else
        state = nil    
      end
    else
      state = nil
    end
    pin_code = self.pin_code
    country = self.country.nil? ? nil : country.try(:name)
    fulladdr = ((busi_address.to_s + ", ") unless busi_address.to_s.blank? ).to_s +
               ((busi_city.to_s + ", ") unless busi_city.to_s.blank? ).to_s + 
               ((state.to_s + ", ") unless state.to_s.blank? ).to_s + 
               country.to_s + 
               (("-" + pin_code.to_s) unless pin_code.to_s.blank? ).to_s
    return fulladdr  
  end

  def get_country
    country =  self.country.nil? ? nil : ISO3166::Country.new(self.country)
    return country.try(:name)
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

  #added by manoranjan
  def get_revenue_collection_business
    tot = 0
    self.payments.active_payment.map{|h| tot = tot + h.get_paid_amount}
    return tot
  end
end
