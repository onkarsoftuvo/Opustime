class FormatContactnoWorker
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform
    p_contacts = PatientContact.where("contact_no is NOT NULL")
    p_contacts.each do |con|
      mod_num = nil
      only_num = con.contact_no.gsub(/[^\d]/, '')
      eleven_digit_num = only_num.slice(0, 11)
      if eleven_digit_num.size < 10
        more_to_add = (10 - eleven_digit_num.size)
        txt = ''
        more_to_add.times{txt << 'X'}
        mod_num = '+1'+txt+eleven_digit_num.to_s
      elsif eleven_digit_num[0] == '1' && eleven_digit_num.size == 11
        mod_num ='+'+eleven_digit_num
      else
        new_num = eleven_digit_num.slice(0, 10)
        mod_num = '+1' + new_num
      end
      logger.info "update patient_contacts set contact_no = #{mod_num} where id = #{con.id}"
      con.update_column(:contact_no, mod_num)
    end
  end
end