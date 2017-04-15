class AllocatePlivoNumber
  include Sidekiq::Worker
  sidekiq_options retry: false
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*50, name: 'allocate_plivo_number_worker'}

  #  Assigning plivo number to subscribed company
  def perform(comp_id)
    if lock.acquire!
      begin
        company = Company.find_by_id(comp_id)
        c_code = company.account.try(:country) rescue 'CA'
        unless company.nil?
          # Choose a Plivo free number
          plivo_obj = PlivoSms::Sms.new
          same_c_code , new_plivo_no = plivo_obj.choose_a_plivo_number(c_code)
          # Buying new one from plivo
          response =  plivo_obj.buy_number(new_plivo_no)
          if  [200,201].include?(response[0])
            formatted_no = PhonyRails.normalize_number(new_plivo_no, country_code: (same_c_code ? c_code : 'CA'))
            company.sms_number.update_attributes(number: formatted_no , :is_trail=> false)
          end
        end
      ensure
        lock.release!
      end
    end
   end
end
