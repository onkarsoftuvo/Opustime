class Subscription < ActiveRecord::Base
  belongs_to :company
  belongs_to :plan
  include Opustime::Utility
  serialize :payment_info, Hash
  serialize :reminders, Hash
  attr_accessor :payment_type
  # has_one :plan , :dependent=> :destroy

  after_update :assign_plivo_number_if_subscribed

  after_update :send_auto_payment_reminder, :if => Proc.new { |subscription| subscription.is_processed }

  after_commit :send_trial_subscription_notification, :if => Proc.new { |subscription| subscription.persisted? && subscription.is_trial }

  def assign_plivo_number_if_subscribed
    #  allocate a number to company and vice versa
    if self.is_subscribed
      exist_country_in_sms_group = SmsGroupCountry.find_by_country(self.company.country)
      if exist_country_in_sms_group.present?
        grp = exist_country_in_sms_group.sms_group
        if grp.incoming_sms == true
          AllocatePlivoNumber.perform_async(self.company.try(:id)) if self.has_trail_number?
        end
      else
        AllocatePlivoNumber.perform_async(self.company.try(:id)) if self.has_trail_number?
      end
    else
      if !(self.has_trail_number?)
        plivo_obj = PlivoSms::Sms.new
        plivo_obj.cancel_number(self.get_assigned_number)
        self.company.sms_number.update_attributes(number: SMS_TRIAL_NO[:stage], :is_trail => true)
      end
    end
  end

  def has_trail_number?
    self.company.sms_number.try(:number).eql?(SMS_TRIAL_NO[:stage])
    # true
  end

  def get_assigned_number
    self.company.sms_number.try(:number)
  end

  def send_auto_payment_reminder
    SubscriptionMailer.sidekiq_delay(:queue => 'subscription').auto_payment_by_wallet(company.id, payment_type)
  end

  def send_trial_subscription_notification
    SubscriptionMailer.sidekiq_delay_for(5.minutes,:queue => 'subscription').trial_subscription(company.id)
  end

  def subscription_days_remaining
    remaining_days = 30 -((Date.today)- self.purchase_date).to_i
    return (remaining_days < 0 ? 0 : remaining_days)
  end


end
