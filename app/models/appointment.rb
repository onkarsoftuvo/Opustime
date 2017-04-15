class Appointment < ActiveRecord::Base
  include PublicActivity::Model
  include PlivoSms
  include Reminder::ReadyMade

  audited only: [:created_at , :appnt_date , :appnt_time_start , :notes , :user_id ,:patient_id , 
                  :appnt_time_end , :patient_arrive , :appnt_status , :updated_at],
                   on: [:update, :destroy , :create] , allow_mass_assignment: true
  
  
  tracked owner: Proc.new { |controller, model| controller.current_user ? controller.current_user : nil } ,
    company: Proc.new { |controller, model| model.patient.company },
    business_id: Proc.new { |controller, model| model.business.try(:id) }

  has_associated_audits
  
  belongs_to :user
  belongs_to :patient

  belongs_to :booker, :polymorphic => true
  belongs_to :canceller, :polymorphic => true
  belongs_to :rescheduler, :polymorphic => true
  
  
  has_one :appointment_types_appointment  , :dependent=> :destroy
  has_one :appointment_type , :through => :appointment_types_appointment , :dependent=> :destroy
  accepts_nested_attributes_for :appointment_types_appointment , :allow_destroy => true
  
  has_one :appointments_business , :dependent=> :destroy
  has_one :business , :through => :appointments_business , :dependent=> :destroy
  accepts_nested_attributes_for :appointments_business , :allow_destroy => true
  
  has_one :wait_lists_appointment , :dependent=> :destroy
  has_one :wait_list , :through => :wait_lists_appointment , :dependent=> :destroy
  accepts_nested_attributes_for :wait_lists_appointment , :allow_destroy => true 
  
  has_many :appointments_invoices ,  :dependent => :destroy
  has_many :invoices , :through=> :appointments_invoices ,  :dependent => :destroy
  
  has_many :treatment_notes_appointments ,  :dependent => :destroy
  has_many :treatment_notes , :through=> :treatment_notes_appointments ,  :dependent => :destroy
  
  scope :active_appointment, ->{ where(status: true)}
  
  validates :repeat_by ,  :inclusion => { :in => %w(day week month),
    :message => "%{value} is not a valid repeat by" } , :allow_nil=> true 
    
  validates  :repeat_start , :repeat_end , :numericality => { :only_integer => true , :greater_than_or_equal_to => 1  } , :unless =>"repeat_by.nil? || repeat_by.blank?"
  validates   :patient_id , :appnt_date , :appnt_time_start , :appnt_time_end , presence: true
  
  validates_presence_of  :user_id
  
  serialize :week_days , Array
  
  validate :end_time_must_be_greater_start_time
  
  after_create :set_remove_on_of_its_associated_wait_list
  
  before_update :check_valid_cancellation_appnt


  after_create do 
    self.update_attributes(:summary => self.appointment_summary_type) if self.summary.nil?
  end

  after_update do 
    self.update_attributes(:summary => self.appointment_summary_type) if (self.summary != self.appointment_summary_type)
  end
  
  has_many :occurrences 
  has_many :childappointments , :through=> :occurrences 
  
  has_one :inverse_occurrence , :class_name => "Occurrence", :foreign_key => "childappointment_id"  
  has_one :inverse_childappointment, :through => :inverse_occurrence , :source => :appointment 
  
  # Creating appointment series on create
  after_create :create_appointment_series
  
  before_create :set_time_stamp_series 
  
  def check_valid_cancellation_appnt
    if (self.status != self.status_was)  && !(self.reason.nil?)
      appnt_cancel_period = self.user.practi_info.try(:cancel_time).to_i
      if (((self.appnt_date - Date.today).to_i < appnt_cancel_period) && appnt_cancel_period > 0 ) 
        self.errors.add(:appointment , "can be cancelled #{appnt_cancel_period} before from creation date ")
      end
    end
  end
  
  def set_time_stamp_series
    if self.inverse_childappointment.nil?
      self.series_time_stamp = self.created_at + 1.second  if self.series_time_stamp.nil?
    else
      parent_appnt = Appointment.find(self.inverse_childappointment.id)
      before_appnt = parent_appnt.childappointments.length == 0 ? parent_appnt : parent_appnt.childappointments.last
      self.series_time_stamp = before_appnt.series_time_stamp + 1.second if self.series_time_stamp.nil?   
    end
  end
  
  
  def end_time_must_be_greater_start_time
    if self.appnt_time_start > self.appnt_time_end
      self.errors.add(:appointment_end_time , "must be greater than start time")
    end 
  end
  
  def create_appointment_series
    if (["day","week","month"].include? self.repeat_by.to_s) && (self.repeat_end.to_i > 1) && (self.week_days.length <=0) 
      if self.repeat_by.to_s.casecmp("day") == 0
        appnt_date = self.appnt_date.to_date + (self.repeat_start.to_i).days
      elsif self.repeat_by.to_s.casecmp("week") == 0
        appnt_date = self.appnt_date.to_date + (self.repeat_start.to_i).week  
      elsif self.repeat_by.to_s.casecmp("month") == 0
        appnt_date = self.appnt_date.to_date + (self.repeat_start.to_i).month 
      end
      repeat_end = self.repeat_end.to_i - 1
      
      next_appointment = self.patient.appointments.new(appnt_date: appnt_date , appnt_time_start: self.appnt_time_start ,repeat_by: self.repeat_by , repeat_start: self.repeat_start , repeat_end: repeat_end , user_id: self.user_id , appnt_time_end: self.appnt_time_end)
      if next_appointment.valid?
        parent_appointment =  (self.inverse_childappointment.nil?) ? self : self.inverse_childappointment
        
        next_appointment.inverse_childappointment = parent_appointment
        next_appointment.unique_key = parent_appointment.unique_key
        next_appointment.appointment_type = parent_appointment.appointment_type
        next_appointment.business = parent_appointment.business
        next_appointment.booker_id = parent_appointment.booker_id
        next_appointment.booker_type = parent_appointment.booker_type
        next_appointment.with_lock do
          next_appointment.save
        end

      end 
      
    end
  end 
  
  def break_series_on_update(flag)
    unless flag == 0 
      if flag == 1
        parent_appoitnment = self.inverse_childappointment
        if parent_appoitnment.nil?
          # all_series_appointments = Appointment.where(["unique_key = ? ", self.unique_key])
          all_series_appointments = self.childappointments.where(["unique_key = ? ", self.unique_key])
        else
          parent_appointment = self.inverse_childappointment
          all_series_appointments = parent_appointment.childappointments.where(["appointments.series_time_stamp >  ? AND unique_key = ? ", self.series_time_stamp , self.unique_key])
        end
        all_series_appointments.each do |child_appnt|
          child_appnt.update_attributes()  
        end 
         
      elsif flag == 2
                
      end
    end 
  end
  
  def set_remove_on_of_its_associated_wait_list
    if self.wait_list.present?
      self.wait_list.update_attributes(:remove_on => self.appnt_date.to_date)
    end
  end 
  
  def name_with_date
    self.appnt_date.strftime("%d %b %Y").to_s + self.appnt_time_start.strftime(", %H:%M%p").to_s + " - " + self.appointment_type.try(:name).to_s
  end

  def time_interval
    self.appnt_time_start.strftime('%H:%M%p').to_s + '-'+ self.appnt_time_end.strftime('%H:%M%p').to_s
  end
  
  def name_with_category
    appnt_type = self.appointment_type
    unless appnt_type.nil?
      return appnt_type.name.to_s + "(" + appnt_type.category.to_s + ")"
    else
      return ""
    end
  end
  
  def date_and_time_without_name
    self.appnt_date.strftime("%d %b %Y").to_s + self.appnt_time_start.strftime(", %H:%M%p").to_s
  end

  # checking total following appointment in series for a particular appointment   
  def has_same_item_series(nos , repeat_by , repeat_start=1 , week_days=[])
    if repeat_by == "week"
      if self.repeat_by.casecmp(repeat_by) == 0 
        parent_appointment = self.inverse_childappointment
        if parent_appointment.nil?
          series_appointments = self.childappointments.where(["unique_key = ?",self.unique_key])
          return (((series_appointments.count + 1) == nos) && (self.repeat_start == repeat_start) && (self.week_days == week_days))
        else 
          series_appointments = parent_appointment.childappointments.where(["unique_key = ? AND appointments.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
          return (series_appointments.count == nos && (self.repeat_start == repeat_start) && (self.week_days == week_days))
        end    
      else
        return false  
      end
    else
      if self.repeat_by.casecmp(repeat_by) == 0 
        parent_appointment = self.inverse_childappointment
        if parent_appointment.nil?
          series_appointments = self.childappointments.where(["unique_key = ?",self.unique_key])
          return (((series_appointments.count + 1) == nos) && (self.repeat_start == repeat_start))
        else 
          series_appointments = parent_appointment.childappointments.where(["unique_key = ? AND appointments.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
          return (series_appointments.count == nos && (self.repeat_start == repeat_start))
        end    
      else
        return false  
      end
    end
  end
  
  def reflect_same_in_all_following
    if self.inverse_childappointment.nil?
      series_appointments = self.childappointments.where(["unique_key = ?",self.unique_key])
    else
      series_appointments = self.inverse_childappointment.childappointments.where(["appointments.unique_key = ? AND appointments.series_time_stamp > ? " , self.unique_key , self.series_time_stamp ])
    end
    
    flag = true 
    series_appointments.each do |appnt|
     flag = match_value_and_into_child(self , appnt)  
    end
    return flag
  end
  
  def remove_following_including_itself
    if self.inverse_childappointment.nil?
      self.childappointments.map{|k| k.destroy}
      self.destroy
    else
      series_appointments = self.inverse_childappointment.childappointments.where(["unique_key = ? AND appointments.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
      series_appointments.map{|k| k.destroy}
    end
  end
  
  def same_all_events_child
    parent_appointment = self.inverse_childappointment
    unless parent_appointment.nil?
      series_appointments = parent_appointment.childappointments.where(["unique_key = ?",parent_appointment.unique_key])
      series_appointments.each do |appnt|
        match_value_and_into_child(self , appnt) unless self == appnt  
      end
      match_value_and_into_child(self , parent_appointment)
    end    
  end
  
  def siblings_in_series
    if self.inverse_childappointment.nil?
      return (self.childappointments.count + 1)
    else
      series_appointments = self.inverse_childappointment.childappointments.where(["appointments.unique_key = ? AND appointments.series_time_stamp > ? " , self.unique_key , self.series_time_stamp ])
      return (series_appointments.count + 1)
    end
  end

 #creating appointment hour and minute if nil
  def time_check_format
    time_period =""
    check_appnt_time = Time.diff(self.appnt_time_end.to_datetime , self.appnt_time_start.to_datetime , "%h:%m")
    if check_appnt_time[:hour] == 0 && check_appnt_time[:minute] == 0
      time_period ="0 minute"
    elsif check_appnt_time[:hour] == 0 && check_appnt_time[:minute] !=0
      if check_appnt_time[:minute] > 1
        time_period = "#{check_appnt_time[:minute]} minutes"
      else
        time_period = "#{check_appnt_time[:minute]} minute"
      end
    elsif check_appnt_time[:minute] == 0 && check_appnt_time[:hour] !=0
      if check_appnt_time[:hour] > 1
        time_period = "#{check_appnt_time[:hour]} hours"
      else  
	    time_period = "#{check_appnt_time[:hour]} hour"
      end
    elsif check_appnt_time[:minute] != 0 && check_appnt_time[:hour] !=0
      if check_appnt_time[:hour] > 1 && check_appnt_time[:minute] > 1
        time_period = "#{check_appnt_time[:hour]}  hours and #{check_appnt_time[:minute]} minutes"
      else
        time_period = "#{check_appnt_time[:hour]}  hour and #{check_appnt_time[:minute]} minute"
      end
    end
    return time_period
  end 
  
  
  def self.create_appointments_weekly_days_wise(company , params_appointment , business = nil)
    appnt_create_datelist = []
    appnt_create_datelist = get_dates_for_specific_days_in_week_range(params_appointment[:appnt_date] , params_appointment[:repeat_start] , params_appointment[:repeat_end] , params_appointment[:week_days])
    flag = true
    parent_appnt = nil
    appnt_create_datelist.each_with_index do |week_date , index|
      params_appointment[:appnt_date] = week_date
      if index > 0 
        params_appointment[:notes] = nil  
      end 
      appointment  = company.appointments.new(params_appointment)
 
      if appointment.valid?
        appointment.unique_key =  index == 0 ? rand(1000000) : parent_appnt.unique_key
        appointment.inverse_childappointment = parent_appnt
        appointment.business = business unless business.nil?
        appointment.with_lock do
          appointment.save
        end

        
        parent_appnt = appointment if index ==0  
        flag = true
      else
        flag = false
        break 
      end 
    end
    return flag   
  end
  
  def has_series
    if self.inverse_childappointment.nil?
      flag = self.childappointments.length > 0
    else
      flag = true
    end
    return flag 
  end
  
  # def weekly_series_status(repeat_by , repeat_start , repeat_end , week_days)
    # if ((self.repeat_by == repeat_by) &&  (self.repeat_start == repeat_start) && (self.repeat_end == repeat_end) && (self.week_days == week_days))
      # return true 
    # else
      # return false
    # end
  # end
  # Getting week no for its following appointments  
  def get_total_week_no
    week_no = 1 
    if self.inverse_childappointment.nil?
      last_appnt =  self.childappointments.last
      unless last_appnt.nil?
        first_appnt_date = self.appnt_date
        last_appnt_date = last_appnt.appnt_date  
        dt_diff = Time.diff(first_appnt_date , last_appnt_date)
        wk = dt_diff[:week]
        days = dt_diff[:day]
        if days > 0 
          week_no = wk + 1 
        else 
          week_no = wk 
        end 
      end
    else
      first_appnt_date = self.appnt_date
      last_appnt_date = self.inverse_childappointment.childappointments.last.appnt_date
      dt_diff = Time.diff(first_appnt_date , last_appnt_date)
      wk = dt_diff[:week]
      days = dt_diff[:day]
      if days > 0 
        week_no = wk + 1 
      else 
        week_no = wk 
      end 
    end
    return week_no
  end
  
  def status_change_itself_and_following_appointments_for_delete
    if self.inverse_childappointment.nil?
      self.childappointments.each do |appnt|
        appnt.update_attributes(:status=> false )
      end
      self.update_attributes(:status=> false )
    else
      series_appointments = self.inverse_childappointment.childappointments.where(["unique_key = ? AND appointments.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
      series_appointments.each do |appnt|
        appnt.update_attributes(:status=> false )
      end
    end
  end 
  
  def status_change_for_all_appnt_in_series
    if self.inverse_childappointment.nil?
      self.childappointments.each do |appnt|
        appnt.update_attributes(:status=> false )
      end
      self.update_attributes(:status=> false )
    else
      parent_appnt = self.inverse_childappointment
      series_appointments = parent_appnt.childappointments
      series_appointments.each do |appnt|
        appnt.update_attributes(:status=> false )
      end
      parent_appnt.update_attributes(:status=> false )
    end
  end
  
  # last Outstanding invoice has first priority to return if not then paid last one 
  def paid_or_outstanding_invoice
    invoices = self.invoices.active_invoice.order(created_at: :desc)
    if invoices.length > 0
      invoices.each do |invoice|
        return invoice if invoice.calculate_outstanding_balance > 0
      end
      return invoices.first
    else
      return nil
    end
  end

  def has_due_invoice?
    flag = false
    invoices = self.invoices.active_invoice.order(created_at: :desc)
    if invoices.length > 0
      invoices.each do |invoice|
        if invoice.calculate_outstanding_balance > 0
          flag = true
          break 
        end
      end
    end
    return flag 
  end
  
  
  def to_ics
    event = Icalendar::Event.new
    
    appnt_date = self.appnt_date  
    dt_y = appnt_date.strftime("%Y").to_i
    dt_m = appnt_date.strftime("%m").to_i
    dt_dt = appnt_date.strftime("%dT").to_i
    
    st_hr = self.appnt_time_start.strftime("%H").to_i
    st_min = self.appnt_time_start.strftime("%M").to_i
    st_sec = self.appnt_time_start.strftime("%S").to_i
    
    end_hr = self.appnt_time_end.strftime("%H").to_i
    end_min = self.appnt_time_end.strftime("%M").to_i
    end_sec = self.appnt_time_end.strftime("%S").to_i
    
    
    start_appnt_date = DateTime.new(dt_y, dt_m ,dt_dt , st_hr , st_min , st_sec)
    end_appnt_date = DateTime.new(dt_y, dt_m ,dt_dt , end_hr , end_min , end_sec) 
    
    # event.start = start_appnt_date.strftime("%Y%m%dT%H%M%S")
    # event.end = end_appnt_date.strftime("%Y%m%dT%H%M%S")
    
    patient = self.patient
    event.description = "You are seeing #{patient.name_for_ical}"
    
    location = self.business
    
    event.location = location.full_address
    # event.klass = "PUBLIC"
    event.created = self.created_at
    event.last_modified = self.updated_at
    service = self.appointment_type
    
    event.summary = "#{service.name} (#{service.category})" 
    # event.add_comment("AF83 - Shake your digital, we do WowWare")
    event
  end

   
  def self.to_csv(options = {})
    column_names = ["APPOINTMENT_DATE" , "PATIENT" ,  "PRACTITIONER" , "SERVICE_TYPE" , "CONTACT_NO" , "EMAIL_ADDRESS" , "BUSINESS_LOCATION"]   
    # column_names = ["PATIENT PRACTITIONER SERVICE_TYPE CONTACT_NO EMAIL_ADDRESS BUSINESS_LOCATION"]   

    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |appnt|
        data = [] 

        apnt_date = appnt.appnt_date.to_date.strftime("%A-%d%B%Y")
        apnt_start_time = appnt.appnt_time_start.strftime("-at%H:%M%p")
        apnt_date = apnt_date + apnt_start_time
        data << apnt_date.to_s.gsub(" ","")

        patient = appnt.patient
        name = patient.full_name.gsub(" ","")
        #cs = patient.concession.try(:name)
        name_with_cs = name.to_s #+ " " + cs.to_s + " "
        data << name_with_cs
        
        data << appnt.user.full_name_with_title.gsub(" ","")
        data << appnt.appointment_type.name.gsub(" ","")
        data << appnt.patient.patient_contacts.first.try(:contact_no)
        data << appnt.patient.try(:email)
        data << appnt.business.try(:name).gsub(" ","")
        # csv << ([] <<data.join(" "))   # Adding appointment record in csv file
        csv << data 
      end
    end
  end

  def appointment_summary_type
    patient = self.patient
    recurring = (!(self.inverse_childappointment.nil?) && self.status == true ) || ((patient.has_appointments_before(self) && self.childappointments.length > 0) && self.status == true)
    if (!(patient.has_appointments_before(self)) && self.status == true )
      status = APPNT_SUMMARY["0"]

    elsif recurring
      status = APPNT_SUMMARY["2"]

    elsif self.missed? && self.status == true
      status = APPNT_SUMMARY["4"]
      
    elsif (((self.audits.last.audited_changes.keys.include?"appnt_time_start") || (self.audits.last.audited_changes.keys.include?"appnt_time_end") && self.audits.count > 1) && self.status == true )
      status = APPNT_SUMMARY["5"]

    elsif ((patient.has_appointments_before(self) && !recurring) && self.status == true )
      status = APPNT_SUMMARY["1"]

    elsif (!(self.cancellation_time.nil?) && self.status == false)
      status = APPNT_SUMMARY["3"]
    end

    return status
  end

  def missed?
     dt = self.date_and_time_without_name.to_datetime
     flag = false
     if (dt < DateTime.now) && (self.invoices.active_invoice.length <= 0)
      flag = true if [nil , false].include? self.patient_arrive     
     end
     return flag
  end

  def series_length
    if self.has_series
      parent_appnt = self.inverse_childappointment
      parent_appnt = self if parent_appnt.nil?
      return (parent_appnt.childappointments.length + 1)
    else
      return 1
    end
  end

  def following_series_length
    if self.inverse_childappointment.nil?
      return (self.childappointments.where(['appointments.status= ? ', true]).count + 1)
    else
      series_appointments = self.inverse_childappointment.childappointments.where(["appointments.status = ? AND appointments.unique_key = ? AND appointments.series_time_stamp > ? ", true , self.unique_key , self.series_time_stamp ])
      return (series_appointments.count + 1)
    end
  end

  def accurate_activity_log_text_reschedule
    msg = {}
    changes = self.audits.last.audited_changes
    changes.delete 'updated_at'
    if changes.keys.include?'appnt_time_start'
      msg[:old_str_time] = changes["appnt_time_start"].first.try(:strftime,"%H:%M%P")
      msg[:new_str_time] = changes["appnt_time_start"].second.strftime("%H:%M%P")      
    else
      msg[:old_str_time] = self.appnt_time_start.strftime("%H:%M%P")          
      msg[:new_str_time] = self.appnt_time_start.strftime("%H:%M%P")          
    end

    if changes.keys.include?'appnt_time_end'
      msg[:old_end_time] = changes["appnt_time_end"].first.try(:strftime,"%H:%M%P")
      msg[:new_end_time] = changes["appnt_time_end"].second.strftime("%H:%M%P")      
    else
      msg[:old_end_time] = self.appnt_time_end.strftime("%H:%M%P")
      msg[:new_end_time] = self.appnt_time_end.strftime("%H:%M%P")          
    end
    
    if changes.keys.include?'appnt_date'
      msg[:old_date] = changes["appnt_date"].first
      msg[:new_date] = changes["appnt_date"].second
    end
    return msg
  end

  def accurate_activity_log_text_appnt_status
    msg = {}
    changes = self.audits.last.audited_changes
    changes.delete 'updated_at'
    if changes.keys.include?'appnt_status'
      msg[:old_appnt_status] = get_appointment_status(changes['appnt_status'][0])
      msg[:new_appnt_status] = get_appointment_status(changes['appnt_status'][1])
    end

    return msg

  end

  def accurate_activity_log_text_patient_status
    msg = {}
    changes = self.audits.last.audited_changes
    changes.delete 'updated_at'
    if changes.keys.include?'patient_arrive'
      msg[:old_patient_status] = get_patient_status(changes['patient_arrive'][0])
      msg[:new_patient_status] = get_patient_status(changes['patient_arrive'][1])
    end

    return msg
  end
  
  # def accurate_activity_log_text_cancel(person)
  #   "Appointment at #{self.date_and_time_without_name} has been cancelled by #{person.full_name} at #{self.cancellation_time}"
  # end

  # creating Activity logs for creation of an appointment or a series of appointments
  # def accurate_activity_log_text_create(flag = false)
  #   msg = ""
  #   counting = self.childappointments.length
  #   if counting > 1
  #     last_one_occur_date = self.childappointments.last.date_and_time_without_name
  #     appnt_type = self.repeat_by
  #     type_wise = (appnt_type == "day") ? "daily" : "#{appnt_type}ly"
  #     booker = self.booker
  #     doctor = self.user
  #     patient = self.patient
  #     msg = "From #{self.date_and_time_without_name} - #{last_one_occur_date}, #{booker.full_name} has #{flag ? "updated": "created"} #{type_wise} #{counting+1} recurring booking with #{doctor.full_name} for patient #{patient.full_name} "
  #   else
  #     booker = self.booker
  #     doctor = self.user
  #     patient = self.patient
  #     msg = "On #{self.date_and_time_without_name} , #{booker.full_name} has #{flag ? "updated": "created"} a booking with #{doctor.full_name} for patient #{patient.full_name} "
  #   end

  #   return msg
  # end

  def formatted_id
    "0"*(6-self.id.to_s.length)+ self.id.to_s
  end

  def send_sms_practitioner(practitioner = true)
    patient = self.patient
    company = patient.company
    src_no = company.sms_number.number
    obj_name = practitioner ? ("#{(patient.full_name_without_title)} has") : ("You have")
    doct_name = practitioner ? 'You' : (self.user.full_name_with_title)
    sms_body = "#{obj_name}  been booked an appointment(#{self.appointment_type.name}) with #{doct_name}" +
        " on #{self.date_and_time_without_name} at Location - #{self.business.name}"
    accurate_no = practitioner ? (self.user.get_primary_contact.try(:phony_normalized)) : (patient.get_primary_contact.try(:phony_normalized))
    plivo_obj = PlivoSms::Sms.new
    response = plivo_obj.send_sms(src_no , accurate_no , sms_body) unless accurate_no.nil?
    unless accurate_no.nil?
      if [200, 202].include? response[0]
        deduct_in_sms_default_no(company.sms_setting) if practitioner
        create_communication_log(company , accurate_no , src_no , sms_body , patient.id)
      end
    end
  end
  
  private

  def get_appointment_status(status_val)
    case status_val
      when nil
        return 'no updates'
      when false
        return 'Pending'
      when true
        return 'Completed'
    end
  end

  def get_patient_status(status_val)
    case status_val
      when nil
        return 'no updates'
      when false
        return 'Absent'
      when true
        return 'Arrived'
    end
  end
  
  def match_value_and_into_child(old_appnt , new_appnt)
    new_appnt.appnt_time_end = old_appnt.appnt_time_end
    new_appnt.appnt_time_start = old_appnt.appnt_time_start
    new_appnt.patient = old_appnt.patient
    new_appnt.appointment_type = old_appnt.appointment_type
    new_appnt.user = old_appnt.user
    new_appnt.with_lock do
      return new_appnt.save
    end

  end
  
  # Getting dates list when weeky appointment is created
  def self.get_dates_for_specific_days_in_week_range(appnt_date , start_no , end_no , days_arr )
    appnt_create_datelist = []
    days_arr.map! { |x| x == 0 ? 7 : x }.flatten
    week_range = get_week_range(appnt_date , start_no , end_no )
    week_range.each do |week_rng|
      ((week_rng.first.to_date)..(week_rng.second.to_date)).each do |apnt_date|
        if days_arr.include? apnt_date.cwday
          appnt_create_datelist <<  apnt_date   
        end
      end
    end
    return appnt_create_datelist  
  end

  def self.get_week_range(appnt_date , start_no , end_no) 
    date_range = []
    count = 1
    begin
      date_item = []
      if (appnt_date.to_date).wday == 6
        date_item = [appnt_date.to_date , appnt_date.to_date]
      elsif (appnt_date.to_date).wday == 0
        date_item = [appnt_date.to_date , appnt_date.to_date + 1.week-1.day]
      else
        date_item = [appnt_date.to_date , appnt_date.to_date.at_end_of_week-1] 
      end 
      end_no = end_no - 1 
      date_range << date_item  if date_item.length > 0
      if date_item.second.to_date.wday == 0
        appnt_date = date_item.second + (start_no-1).weeks
      else
        appnt_date = (date_item.second + 1.day) + (start_no-1).weeks
      end
      
    end while end_no > 0 
    return  date_range
  end
  
  
  
  
end
