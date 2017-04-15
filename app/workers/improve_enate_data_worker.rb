class ImproveEnateDataWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(file_name)
    @import_data = JSON.parse(File.read("public/import_files/inv-#{file_name}.json"))
    @import_data.each do |import|
      if import['amount_paid'].to_i > 0
        invoice = Invoice.find_by(enate_id: import['enateId'])
        invoice_payment = InvoicesPayment.find_by(invoice_id: invoice.id)
        invoice_payment.update_column(:amount,import['amount_paid'].to_i)
        payment_type_payment = PaymentTypesPayment.find_by(payment_id: invoice_payment.payment_id)
        payment_type_payment.update_column(:amount,import['amount_paid'].to_i)
      end
    end

    #remove enate data
    # invoices  = Invoices.where("enate_id IS NOT NULL")
    # invoices.each do |inv|
    #   inv.destroy
    # end
  end
end
