class PatientMailer < ApplicationMailer
  default from: 'no-reply@opustime.com'

  def account_statement_email(patient , email_to , user , pdf =nil )
    # pdf = AccountStatementPdf.new(patient)
    # send_data pdf.render, filename: 'report.pdf', type: 'application/pdf'
    @email_to_flag = false
    @patient = patient
    @business = @patient.company.businesses.head.first
    unless email_to.nil?  || email_to.blank?
      to_email = ""
      if email_to.casecmp("patient")==0
        to_email = @patient.email
        @email_to_flag = true
      elsif email_to.casecmp("other")==0
        to_email = @patient.invoice_email
        @email_to_flag = false
      end
      attachments['account-statement.pdf'] = pdf
      mail(to: to_email , :from=>@patient.company.communication_email , subject: "Account Statement - #{@business.name}")
    end
  end
  
  def invoice_email(patient ,email_to ,  invoice , pdf =nil )
    @patient = patient
    @business = @patient.company.businesses.head.first
    @invoice = invoice
    unless email_to.nil?  || email_to.blank?
      to_email = ""
      if email_to.casecmp("patient")==0
        to_email = @patient.email
        @email_to_flag = true
      elsif email_to.casecmp("other")==0
        to_email = @patient.invoice_email
        @email_to_flag = false
      end

    attachments["invoice-#{@invoice.formatted_id}.pdf"] = pdf
        mail(to: to_email , :from=>@patient.company.communication_email , subject: "Invoice ##{@invoice.number} - #{@business.name}")
    end
  end

end
