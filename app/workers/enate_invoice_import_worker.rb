class EnateInvoiceImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform(company,user,business)
    PublicActivity.enabled = false
    @user = User.find_by(id: user)
		payment_type =  PaymentType.where(company_id: company, name: 'Cash')[0].id
    @import_data = JSON.parse(File.read("public/import_files/#{company}/inv-#{@user.first_name}.json"))
    @import_data.each do |import|
      invoice_data = serialize_invoice_data(import,user,business)
      invoice = Invoice.find_or_initialize_by(invoice_data)
			Invoice.skip_callback(:save, :before, :generate_invoice_number)
      if invoice.save(validate: false)
        #save invoice user
        invoice_user_data = {}
        invoice_user_data['user_id'] = user
        invoice_user_data['invoice_id'] = invoice.id
        invoice_user = InvoicesUser.find_or_initialize_by(invoice_user_data)
        invoice_user.save(validate: false)

        #save invoice business
        invoice_business_data = {}
        invoice_business_data['invoice_id'] = invoice.id
        invoice_business_data['business_id'] = business
        invoice_business = BusinessesInvoice.find_or_initialize_by(invoice_business_data)
        invoice_business.save(validate: false)

        #save payments
        if import['amount_paid'].to_i > 0
          payment_data = {}
          payment_data['businessid'] = business
          payment_data['payment_date'] = invoice.close_date
          payment_data['patient_id'] = invoice.patient_id
          payment_data['creater_id'] = user
          payment_data['creater_type'] = 'User'
          payment = Payment.find_or_initialize_by(payment_data)
          if payment.save(validate: false)
            payment_type_payments_data = {}
            payment_type_payments_data['amount'] = invoice.invoice_amount
            payment_type_payments_data['payment_type_id'] = payment_type
            payment_type_payments_data['payment_id'] = payment.id
            payment_type_payments = PaymentTypesPayment.find_or_initialize_by(payment_type_payments_data)
            payment_type_payments.save(validate: false)

            #save invoice payment
            invoice_payment_data = {}
            invoice_payment_data['amount'] = invoice.invoice_amount
            invoice_payment_data['payment_id'] = payment.id
            invoice_payment_data['invoice_id'] = invoice.id
            invoice_payment = InvoicesPayment.find_or_initialize_by(invoice_payment_data)
            invoice_payment.save(validate: false)

            #save business payment
            business_payment_data = {}
            business_payment_data['business_id'] = business
            business_payment_data['payment_id'] = payment.id
            business_payment = BusinessesPayment.find_or_initialize_by(business_payment_data)
            business_payment.save(validate: false)
          end
        end
			end
		end
		# render :json=> {:flag=> true }
  end

  def serialize_invoice_data(invoice_data,user,business)
    data = {}
    data['enate_id'] = invoice_data['enateId']
    data['issue_date'] = invoice_data['billing_date']
    data['invoice_amount'] = invoice_data['amount_owed']
    data['subtotal'] = invoice_data['amount_owed']
    data['close_date'] = invoice_data['billing_date'] if invoice_data['amount_paid'].to_i > 0
    patient = Patient.find_by(enate_id: invoice_data['enate_patient_id'])
    if patient.present?
      data['patientid'] = patient.id
      data['patient_id'] = patient.id
    end
    data['creater_id'] = user
    data['creater_type'] = 'User'
    data['updater_id'] = user
    data['updater_type'] = 'User'
		data['businessid'] = business
    return data
  end
end
