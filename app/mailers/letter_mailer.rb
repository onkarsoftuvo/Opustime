class LetterMailer < ApplicationMailer
  default from: 'no-reply@opustime.com'
 
  def letter_email(email_recepiants , from_email ,  letter, email_subject ,email_body=nil , pdf= nil)
    @letter = letter
    @email_body = email_body 
    attachments['letter.pdf'] = pdf unless pdf.nil?
    mail(to: email_recepiants , :from=>from_email , subject: email_subject )
  end
end
