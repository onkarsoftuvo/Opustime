class LettersWorker
  include Sidekiq::Worker
  sidekiq_options retry: true
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*25, name: 'letter_worker'}
  
  def perform(email_recipients , from ,  letter_id, letter_subject)
    if lock.acquire!
      begin
        letter = Letter.find_by_id(letter_id)
        LetterMailer.letter_email(email_recipients , from ,  letter , letter_subject).deliver_now
        patient = letter.patient
        patient.communications.create(comm_time: Time.now, comm_type: "email", category: "Letter", direction: "sent", to: patient.email, from: patient.company.communication_email, message: Nokogiri::HTML(letter.content).text , send_status: true) unless patient.nil?
      ensure
        lock.release!
      end

    end
  end
end