module PlivoSms
  class Sms
    include Plivo

    def initialize
      @service = RestAPI.new(CONFIG[:plivo_access_id], CONFIG[:plivo_secret_id])
    end

    def send_sms(src_no, accurate_no, sms_body)
      sms_params = {
          'src' => src_no,
          'dst' => accurate_no,
          'text' => sms_body
      }
      response = @service.send_message(sms_params)
      return response
    end

    def choose_a_plivo_number(country_iso='CA', flag = true)
      numbers = @service.search_phone_number({"country_iso" => country_iso})
      avail_free_numbers_for_a_country = (numbers[1]['objects'].length > 0 ?  (numbers[1]['objects'].map{|k| k['number']}) : [])
      if avail_free_numbers_for_a_country.length > 0
        return flag , avail_free_numbers_for_a_country[rand(avail_free_numbers_for_a_country.length)]
      else
        choose_a_plivo_number('CA' , false)
      end
    end

    # rent a Plivo number
    def buy_number(selected_number)
      @service.buy_phone_number({"number" => selected_number})
    end

    # unrent a Plivo number
    def cancel_number(selected_number)
      selected_number = selected_number[1,selected_number.length] if selected_number.include?('+')
      @service.unrent_number({"number" => selected_number})
    end

  end
end
