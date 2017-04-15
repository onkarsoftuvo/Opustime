class ImproveEnateWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform()
    PublicActivity.enabled = false
    @import_data = JSON.parse(File.read("public/import_files/fileNo.json"))
    @import_data.each do |import|
      patient = Patient.find_by(enate_id: import['enateId'])
      if patient.present?
        patient.update_column(:file_number, import['fileNumber'])
        bal = import['balance'].to_i
        if bal != 0
          company = patient.company.id
          business = patient.company.businesses.first.id
          user = patient.company.users.first.id
          item = BillableItem.find_by(name: 'E-nate Ajustment', company_id: company)
          if bal > 0
            payment_type =  PaymentType.where(company_id: company, name: 'Cash')[0].id
            #create a payment
            payment_data = {}
            payment_data['businessid'] = business
            payment_data['payment_date'] = '2017-01-01 00:00:00'
            payment_data['patient_id'] = patient.id
            payment_data['creater_id'] = user
            payment_data['creater_type'] = 'User'
            payment_data['created_at'] = '2017-01-01 00:00:00'
            payment_data['updated_at'] = '2017-01-01 00:00:00'
            if payment = Payment.new(payment_data)
              payment.save(validate: false)
              payment_type_payments_data = {}
              payment_type_payments_data['amount'] = bal.abs
              payment_type_payments_data['payment_type_id'] = payment_type
              payment_type_payments_data['payment_id'] = payment.id
              payment_type_payments_data['created_at'] = '2017-01-01 00:00:00'
              payment_type_payments_data['updated_at'] = '2017-01-01 00:00:00'
              payment_type_payments = PaymentTypesPayment.new(payment_type_payments_data)
              payment_type_payments.save(validate: false)

              #save business payment
              business_payment_data = {}
              business_payment_data['business_id'] = business
              business_payment_data['payment_id'] = payment.id
              business_payment_data['created_at'] = '2017-01-01 00:00:00'
              business_payment_data['updated_at'] = '2017-01-01 00:00:00'
              business_payment = BusinessesPayment.new( )
              business_payment.save(validate: false)
            end
          else
            invoice_data = serialize_invoice_data(patient.id,user,bal,business)
            Invoice.skip_callback(:save, :before, :generate_invoice_number)
            invoice = Invoice.new(invoice_data)
            if invoice.save(validate: false)
              #save invoice user
              invoice_user_data = {}
              invoice_user_data['user_id'] = user
              invoice_user_data['invoice_id'] = invoice.id
              invoice_user_data['created_at'] = '2017-01-01 00:00:00'
              invoice_user_data['updated_at'] = '2017-01-01 00:00:00'
              invoice_user = InvoicesUser.new(invoice_user_data)
              invoice_user.save(validate: false)

              #save invoice business
              invoice_business_data = {}
              invoice_business_data['invoice_id'] = invoice.id
              invoice_business_data['business_id'] = business
              invoice_business_data['created_at'] = '2017-01-01 00:00:00'
              invoice_business_data['updated_at'] = '2017-01-01 00:00:00'
              invoice_business = BusinessesInvoice.new(invoice_business_data)
              invoice_business.save(validate: false)

              item_data={}
              item_data['item_id'] = item.id if item.present?
              item_data['item_type'] = 'BillableItem'
              item_data['unit_price'] = bal.abs
              item_data['quantity'] = 1
              item_data['total_price'] = bal.abs
              item_data['invoice_id'] = invoice.id
              item_data['created_at'] = '2017-01-01 00:00:00'
              item_data['updated_at'] = '2017-01-01 00:00:00'
              item_inv_rel = InvoiceItem.new(item_data)
              item_inv_rel.save(validate: false)
            end
          end
        end
      end
    end
  end

  def serialize_invoice_data(patient,user,balance,business)
    data = {}
    data['issue_date'] = '2017-01-01'
    data['invoice_amount'] = balance.abs
    data['subtotal'] = balance.abs
    data['patientid'] = patient
    data['patient_id'] = patient
    data['creater_id'] = user
    data['creater_type'] = 'User'
    data['updater_id'] = user
    data['updater_type'] = 'User'
    data['businessid'] = business
    # data['created_at'] = '2017-01-01 00:00:00'
    # data['updated_at'] = '2017-01-01 00:00:00'
    data
  end
end
