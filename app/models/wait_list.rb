require "rake"

Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
Enake::Application.load_tasks # providing your application name is 'sample'


class WaitList < ActiveRecord::Base
  belongs_to :company
  
  has_one :wait_lists_patient , :dependent=> :destroy
  has_one :patient , :through=> :wait_lists_patient ,:dependent=> :destroy
  accepts_nested_attributes_for :wait_lists_patient , :allow_destroy => true
  
  has_one :appointment_types_wait_list , :dependent=> :destroy
  has_one :appointment_type , :through=> :appointment_types_wait_list ,:dependent=> :destroy
  accepts_nested_attributes_for :appointment_types_wait_list , :allow_destroy => true
  
  has_many :wait_lists_businesses , :dependent=> :destroy
  has_many :businesses , :through=> :wait_lists_businesses ,:dependent=> :destroy
  accepts_nested_attributes_for :wait_lists_businesses , :allow_destroy => true
  
  has_many :wait_lists_users , :dependent=> :destroy
  has_many :users , -> { where("is_doctor= ? AND acc_active=?" , true, true) } , :through=> :wait_lists_users , :dependent => :destroy
  accepts_nested_attributes_for :wait_lists_users , :allow_destroy => true
  
  has_one :wait_lists_appointment , :dependent=> :destroy
  has_one :appointment , :through => :wait_lists_appointment , :dependent=> :destroy
  accepts_nested_attributes_for :wait_lists_appointment , :allow_destroy => true  
  
  serialize :availability , JSON
  serialize :options , JSON
  
  before_save :set_default_availability
  before_save :set_default_options
  
  validates_presence_of :wait_lists_patient 
  
  validates_presence_of :appointment_types_wait_list 
  
  validates_presence_of :wait_lists_businesses , :message=> "must be seletced atleast one"
  
  validates_presence_of :wait_lists_users , :message=> "must be seletced atleast one"
  
  validate :remove_on_date_cannot_be_in_the_past_or_presence
 
  validate :check_wait_lit_day_should_not_be_blank
  scope :active_wait_list, ->{ where(status: true)}

  def self.run_rake
    Rake::Task['auto_remove_waitlist_on_expire'].reenable
    Rake::Task['auto_remove_waitlist_on_expire'].invoke
  end
  
  def set_default_availability
    
    if self.availability.nil?
      self.availability = {:monday => false , :tuesday => false , :wednesday=> false , :thursday => false , :friday=> false , :saturday=> false , :sunday=> false }
    else
      item = {}
      (["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]- self.availability.keys).each do |day_key|
        item[day_key.to_sym] = false
      end
      self.availability = self.availability.merge item 
    end 
     
  end
  
  def set_default_options
    self.options = {:urgent=> false , :outside_hours => false} if self.options.nil?
  end
  
  def check_wait_lit_day_should_not_be_blank
    if self.availability.nil? || !(self.availability.values.uniq.include?true) 
      errors.add(:select , "at least one day")
    else 
      return true
    end
  end
  
  def remove_on_date_cannot_be_in_the_past_or_presence
    if !remove_on.blank? and remove_on <= Date.today
      errors.add(:remove_on, "must be future date")
    end
  end
  
end
