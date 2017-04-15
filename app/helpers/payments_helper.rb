module PaymentsHelper
  def get_business_name(business)
    result_hash = {}
    # business = Business.find(id) rescue nil
    result_hash[:id] = business.id
    result_hash[:name] = business.name
    return result_hash
  end
  
  def get_patient_info(obj, object="payment")
    # if object.casecmp("payment") == 0
      # patient = which_patient(obj.patient_id) 
    # else
      # patient = obj.patient  #which_patient(obj.patientid)
    # end
    patient = obj.patient
    result_hash = {}
    result_hash[:id] = patient.id
    result_hash[:title] = patient.title
    result_hash[:first_name] = patient.first_name.to_s 
    result_hash[:last_name] = patient.last_name.to_s
    result_hash[:email_to_patient] = patient.try(:email)
    result_hash[:patient_outstanding] = patient.calculate_patient_outstanding_balance  # patient.outstanding_balance.to_f + payment.invoices_payments.map(&:amount).compact.sum.to_f
    result_hash[:credit_account] = patient.calculate_patient_credit_amount.round(2) #patient.credit_amount
    return result_hash 
  end
  
  def which_patient(id)
    patient = Patient.find(id)
  end
  
  def id_format(obj)
    formatted_id = "0"*(6-obj.id.to_s.length)+ obj.id.to_s
    return formatted_id
  end
  
  # def set_date_time_for_payment(params)
  #   date = params[:payment][:payment_date]
  #   # time = params[:payment][:payment_hr].to_s+":"+params[:payment][:payment_min].to_s+":"+"00"
  #   # time =  Time.parse(time).seconds_since_midnight.seconds
  #   # t = Time.now
  #   # t.strftime("%I:%M:%p")
  #   date_time = date+' '+ '00:00:00'
  #   # res = DateTime.parse(date_time)
  #   # formatted_date = res.strftime('%Y-%m-%d %H:%M:%S')
  #
  #   return date_time
  #   # return DateTime.now
  # end

  def set_date_time_for_payment(params)
    date = params[:payment][:payment_date]
    # time = params[:payment][:payment_hr].to_s+":"+params[:payment][:payment_min].to_s
    # date_time = date.to_date + Time.parse(time).seconds_since_midnight.seconds
    return date
    # return DateTime.now
  end
  
  def deposited_amount_of_invoice(invoice_id,payment_id)
    invoices_payments = InvoicesPayment.where(invoice_id: invoice_id , payment_id: payment_id , status: true).select("amount , credit_amount")
    total_amount = invoices_payments.map(&:amount).compact.sum
    total_credit_amount = invoices_payments.map(&:credit_amount).compact.sum
    return total_amount + total_credit_amount  
  end
  
  def practitioner_name(id)
    practitioner = User.find(id)
    full_name = practitioner.first_name + " " + practitioner.last_name  
    return full_name 
  end

end