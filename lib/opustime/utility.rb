module Opustime
  module Utility

    # Rails ActiveSupport::TimeZone lookup and return matched rails timeZone
    # input is like this "(UTC-06:00) Central Time (US & Canada)"
    # after removing UTC offset it becomes like this "Central Time (US & Canada)"

    def timeZone_lookup(time_zone)
      time_zone.present? ? time_zone : 'UTC'
    end

    def user_country_code(user)
      case user.class.to_s
        when 'Patient'
          return user.country rescue 'CA'
        when 'Contact'
          return user.country rescue 'CA'
        when 'User'
          return user.company.account.country rescue 'CA'
        when 'SmsSetting'
          return user.company.account.country rescue 'CA'
        else
          return 'CA'
      end
    end

    def total_days(end_date, start_date)
      return (end_date.to_date - start_date.to_date).to_i
    end

    def plan_consumable_amount(plan_amount, plan_category, use_days)
      # here plan duration in days we are considering 30 days in a month
      plan_duration = plan_category.to_s.eql?('Yearly') ? 365 : 30
      return ((plan_amount.to_f/plan_duration)*use_days).round(2)
    end

    def pro_rata_balance(plan_amount, plan_category, use_days)
      return plan_amount - plan_consumable_amount(plan_amount, plan_category, use_days)
    end

    # this function returns next plan charges if current plan changes
    # in mid of billing cycle
    def lower_to_higher_plan_charges(next_plan, current_plan, current_plan_use_days)
      return (next_plan.price - pro_rata_balance(current_plan.cost, current_plan.category, current_plan_use_days)).round(2)
    end

    # this function returns company wallet credit and next plan charges if current plan charges
    # in mid of billing cycle
    def higher_to_lower_plan_charges(next_plan, current_plan, current_plan_use_days)
      pro_balance = pro_rata_balance(current_plan.cost, current_plan.category, current_plan_use_days)
      # return payable_amount, wallet_credit
      (pro_balance > next_plan.price) ? (return 0, (pro_balance - next_plan.price).round(2)) : (return (next_plan.price - pro_balance).round(2), 0)
    end

    def modify_hash_by_key(hash, key)
      hash.has_key?(key) ? (hash["#{key}"] = true) : hash.merge!("#{key}" => true)
      return hash
    end

    def is_payment_processed?(hash, key)
      return hash.has_key?(key) ? hash["#{key}"] : false
    end

  end
end