class Availability < ActiveRecord::Base
  belongs_to :user

  validates_presence_of  :user_id
  validates :repeat ,  :inclusion => { :in => %w(day week month),
                                       :message => "%{value} is not a valid repeat by" } , :allow_nil=> true

  validates  :repeat_every , :ends_after , :numericality => { :only_integer => true , :greater_than_or_equal_to => 1  } , :unless =>"repeat.nil? || repeat.blank?" ,  :allow_nil=> true

  # validates :avail_date, uniqueness: { scope: [:avail_time_start, :avail_time_end],
  # message: "already exists on same day and time." }
  #
  validates_presence_of :avail_date , :avail_time_start , :avail_time_end

  scope :active_avail, ->{ where(status: true)}

  serialize :week_days , Array


  scope :extra_avails , ->{ where(status: true , is_block: false)}
  scope :extra_unavails , ->{ where(status: true , is_block: true)}

  has_one :availabilities_business , :dependent => :destroy
  has_one :business , :through=> :availabilities_business ,  :dependent => :destroy
  accepts_nested_attributes_for :availabilities_business , :allow_destroy => true

  has_many :occurrence_avails
  has_many :childavailabilities , :through=> :occurrence_avails

  has_one :inverse_occurrence_avail , :class_name => "OccurrenceAvail", :foreign_key => "childavailability_id"
  has_one :inverse_childavailability , :through => :inverse_occurrence_avail , :source => :availability

  after_create :create_availabilities_series

  before_create :set_time_stamp_series

  def create_availabilities_series
    if (["day","week","month"].include? self.repeat.to_s) && (self.ends_after.to_i > 1) && (self.week_days.length <=0)
      if self.repeat.to_s.casecmp("day") == 0
        avail_date = self.avail_date.to_date + (self.repeat_every.to_i).days
      elsif self.repeat_by.to_s.casecmp("week") == 0
        avail_date = self.avail_date.to_date + (self.repeat_every.to_i).week
      elsif self.repeat_by.to_s.casecmp("month") == 0
        avail_date = self.avail_date.to_date + (self.repeat_every.to_i).month
      end
      ends_after = self.ends_after.to_i - 1



      next_avail = self.user.availabilities.new(avail_date: avail_date , avail_time_start: self.avail_time_start ,repeat: self.repeat , repeat_every: self.repeat_every , ends_after: ends_after , avail_time_end: self.avail_time_end)
      if next_avail.valid?
        parent_avail =  (self.inverse_childavailability.nil?) ? self : self.inverse_childavailability

        next_avail.inverse_childavailability = parent_avail
        next_avail.unique_key = parent_avail.unique_key
        next_avail.business = parent_avail.business
        next_avail.is_block = parent_avail.nil? ? false : parent_avail.is_block
        next_avail.save
      end

    end
  end

  def set_time_stamp_series
    if self.inverse_childavailability.nil?
      self.series_time_stamp = self.created_at + 1.second  if self.series_time_stamp.nil?
    else
      parent_avail = Availability.find(self.inverse_childavailability.id)
      before_avail = parent_avail.childavailabilities.length == 0 ? parent_avail : parent_avail.childavailabilities.last
      self.series_time_stamp = before_avail.series_time_stamp + 1.second if self.series_time_stamp.nil?
    end
  end

  def self.create_availability_weekly_days_wise(practitioner , avail_params , business = nil)
    avail_create_datelist = []
    avail_create_datelist = get_dates_for_specific_days_in_week_range(avail_params[:avail_date] , avail_params[:repeat_every] , avail_params[:ends_after] , avail_params[:week_days] )
    flag = true
    parent_avail = nil
    avail_create_datelist.each_with_index do |week_date , index|
      avail_params[:avail_date] = week_date
      if index > 0
        avail_params[:notes] = nil
      end
      avail  = practitioner.availabilities.new(avail_params)

      if avail.valid?
        avail.unique_key =  index == 0 ? rand(1000000) : parent_avail.unique_key
        avail.inverse_childavailability = parent_avail
        avail.business = business unless business.nil?
        avail.is_block = avail_params[:is_block]
        avail.save

        parent_avail = avail if index ==0
        flag = true
      else
        flag = false
        break
      end
    end
    return flag
  end

  # Getting dates list when weeky appointment is created
  def self.get_dates_for_specific_days_in_week_range(appnt_date , start_no , end_no , days_arr )
    appnt_create_datelist = []
    days_arr.map! { |x| x == 0 ? 7 : x }.flatten!
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

  def has_series
    if self.inverse_childavailability.nil?
      flag = self.childavailabilities.length > 0
    else
      flag = true
    end
    return flag
  end

  # Getting week no for its following availabilities
  def get_total_week_no
    week_no = 1
    if self.inverse_childavailability.nil?
      last_avail =  self.childavailabilities.last
      unless last_avail.nil?
        first_avail_date = self.avail_date
        last_avail_date = last_avail.avail_date
        dt_diff = Time.diff(first_avail_date , last_avail_date)
        wk = dt_diff[:week]
        days = dt_diff[:day]
        if days > 0
          week_no = wk + 1
        else
          week_no = wk
        end
      end
    else
      first_avail_date = self.avail_date
      last_avail_date = self.inverse_childavailability.childavailabilities.last.avail_date
      dt_diff = Time.diff(first_avail_date , last_avail_date)
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

  def siblings_in_series
    if self.inverse_childavailability.nil?
      return (self.childavailabilities.count + 1)
    else
      series_avails = self.inverse_childavailability.childavailabilities.where(["availabilities.unique_key = ? AND availabilities.series_time_stamp > ? " , self.unique_key , self.series_time_stamp ])
      return (series_avails.count + 1)
    end
  end

  def same_all_events_child
    parent_avail = self.inverse_childavailability
    unless parent_avail.nil?
      series_appointments = parent_avail.childavailabilities.where(["unique_key = ?",parent_avail.unique_key])
      series_appointments.each do |appnt|
        match_value_and_into_child(self , appnt) unless self == appnt
      end
      match_value_and_into_child(self , parent_avail)
    end
  end

  # checking total following availabilities in series for a particular availability
  def has_same_item_series(nos , repeat_by , repeat_start=1 , week_days=[])
    if repeat_by == "week"
      if self.repeat.casecmp(repeat_by) == 0
        parent_avail = self.inverse_childavailability
        if parent_avail.nil?
          series_avails = self.childavailabilities.where(["unique_key = ?",self.unique_key])
          return (((series_avails.count + 1) == nos) && (self.repeat_every == repeat_start) && (self.week_days == week_days))
        else
          series_avails = parent_avail.childavailabilities.where(["unique_key = ? AND availabilities.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
          return (series_avails.count == nos && (self.repeat_every == repeat_start) && (self.week_days == week_days))
        end
      else
        return false
      end
    else
      if self.repeat.casecmp(repeat_by) == 0
        parent_avail = self.inverse_childavailability
        if parent_avail.nil?
          series_avails = self.childavailabilities.where(["unique_key = ?",self.unique_key])
          return (((series_avails.count + 1) == nos) && (self.repeat_every == repeat_start))
        else
          series_avails = parent_avail.childavailabilities.where(["unique_key = ? AND availabilities.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
          return (series_avails.count == nos && (self.repeat_every == repeat_start))
        end
      else
        return false
      end
    end
  end

  def reflect_same_in_all_following
    if self.inverse_childavailability.nil?
      series_avails = self.childavailabilities.where(["unique_key = ?",self.unique_key])
    else
      series_avails = self.inverse_childavailability.childavailabilities.where(["availabilities.unique_key = ? AND availabilities.series_time_stamp > ? " , self.unique_key , self.series_time_stamp ])
    end

    flag = true
    series_avails.each do |avail|
      flag = match_value_and_into_child(self , avail)
    end
    return flag
  end

  def remove_following_including_itself
    if self.inverse_childavailability.nil?
      self.childavailabilities.map{|k| k.destroy}
      self.destroy
    else
      series_avails = self.inverse_childavailability.childavailabilities.where(["unique_key = ? AND availabilities.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
      series_avails.map{|k| k.destroy}
    end
  end




  #creating appointment hour and minute if nil
  def time_check_format
    time_period =""
    check_avail_time = Time.diff(self.avail_time_end.to_datetime , self.avail_time_start.to_datetime , "%h:%m")
    if check_avail_time[:hour] == 0 && check_avail_time[:minute] == 0
      time_period ="0 minute"
    elsif check_avail_time[:hour] == 0 && check_avail_time[:minute] !=0
      if check_avail_time[:minute] > 1
        time_period = "#{check_avail_time[:minute]} minutes"
      else
        time_period = "#{check_avail_time[:minute]} minute"
      end
    elsif check_avail_time[:minute] == 0 && check_avail_time[:hour] !=0
      if check_avail_time[:hour] > 1
        time_period = "#{check_avail_time[:hour]} hours"
      else
        time_period = "#{check_avail_time[:hour]} hours"
      end
    elsif check_avail_time[:minute] != 0 && check_avail_time[:hour] !=0
      if check_avail_time[:hour] > 1 && check_avail_time[:minute] > 1
        time_period = "#{check_avail_time[:hour]}  hours and #{check_avail_time[:minute]} minutes"
      else
        time_period = "#{check_avail_time[:hour]}  hour and #{check_avail_time[:minute]} minute"
      end
    end
    return time_period
  end

  def status_change_itself_and_following_availabilities_for_delete
    if self.inverse_childavailability.nil?
      self.childavailabilities.each do |avail|
        avail.update_attributes(:status=> false )
      end
      self.update_attributes(:status=> false )
    else
      series_avails = self.inverse_childavailability.childavailabilities.where(["unique_key = ? AND availabilities.series_time_stamp >= ? " , self.unique_key ,  self.series_time_stamp])
      series_avails.each do |avail|
        avail.update_attributes(:status=> false )
      end
    end
  end

  def status_change_for_all_avails_in_series
    if self.inverse_childavailability.nil?
      self.childavailabilities.each do |avail|
        avail.update_attributes(:status=> false )
      end
      self.update_attributes(:status=> false )
    else
      parent_avail = self.inverse_childavailability
      series_avails = parent_avail.childavailabilities
      series_avails.each do |avail|
        avail.update_attributes(:status=> false )
      end
      parent_avail.update_attributes(:status=> false )
    end
  end



  private

  def match_value_and_into_child(old_avail , new_avail)
    new_avail.avail_time_end = old_avail.avail_time_end
    new_avail.avail_time_start = old_avail.avail_time_start
    new_avail.user = old_avail.user
    return new_avail.save
  end

end
