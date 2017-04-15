require 'csv'
require 'json'
class EnateimportController < ApplicationController
	respond_to :json
  skip_before_action :current_user
  before_action :find_company_by_sub_domain
    # before_filter :authorize
    # before_action :find_company
    before_action :find_doc

		# def destroy_enate_data
		# 	@import_data = JSON.parse(File.read("public/import_files/fileNo.json"))
	   #  @import_data.each do |import|
		# 		patient = Patient.find_by(enate_id: import['enateId'])
     #    raise patient.company.users.first.inspect
		# 		# if patient.present?
     #      # patient.update_column(:file_number, import['fileNumber'])
     #    bal = import['balance'].to_i
     #      if bal != 0
     #        if bal > 0
     #          print 'invoice'
     #        else
     #          print 'payment'
     #        end
     #        raise import['balance'].inspect
     #      end
		# 		# end
		# 	end
		# end

    def improve_enate
      ImproveEnateWorker.perform_async()
      render :json=> {:flag=> true }
    end

		def csv_import
			# CsvImportWorker.perform_async(@company.id)
			@import_data = CSV.parse(File.read('public/import_files/patientDataToExport.csv'), :headers => true, :col_sep => ";")
			transformed_data = @import_data.map { |row| row.to_hash }
			# raise transformed_data.first['first_name'].inspect
			transformed_data.each do |import|
				# raise import.inspect
	      patient_data = serialize_patient_data_csv(import)
	      patient = Patient.find_or_initialize_by(patient_data)
	      if patient.save(validate: false)
	        phone_type = ['home', 'work']
	        phone_type.each do |type|
	          unless import["#{type}"].blank?
	            contact_data = {}
	            contact_data['contact_no'] = import["#{type}"]
	            contact_data['contact_type'] = type
	            contact_data['patient_id'] = patient.id
	            contact = PatientContact.find_or_initialize_by(contact_data)
	            contact.save(validate: false)
	          end
	        end
	      end
			end
		end


	def improve_import
		ImproveEnateDataWorker.perform_async(params[:file_name])
		render :json=> {:flag=> true }
	end

	def import
		case params[:type]
		when 'patients'
			# import_patients
			EnatePatientImportWorker.perform_async(@company.id,@user.id,params[:business])
			render :json=> {:flag=> true }
    when 'items'
			EnateItemsImportWorker.perform_async(@company.id,@user.id,params[:business])
			# import_billable_items
			render :json=> {:flag=> true }
    when 'invoices'
			EnateInvoiceImportWorker.perform_async(@company.id,@user.id,params[:business])
			# import_invoices
			render :json=> {:flag=> true }
		when 'relations'
		  import_item_inv_rel
			# render :json=> {:flag=> true }
		end
  end

  def import_patients
    @import_data = JSON.parse(File.read("public/import_files/#{@company.id}/pat-#{@user.first_name}.json"))
		# raise @import_data.count.inspect
		@import_data.each do |import|
      patient_data = serialize_patient_data(import)
      patient = Patient.find_or_initialize_by(patient_data)
      if patient.save(validate: false)
        phone_type = ['cell_phone', 'home_phone', 'work_phone']
        phone_type.each do |type|
          unless import["#{type}"].blank?
            contact_no = import["#{type}"]
            if type == 'work_phone'
              contact_no = "#{import['work_phone_ext']}" + "-" + "#{import['work_phone']}" unless import['work_phone_ext'].blank?
            end
            contact_data = {}
            contact_data['contact_no'] = contact_no
            contact_data['contact_type'] = type.split('_')[0]
            contact_data['patient_id'] = patient.id
            contact = PatientContact.find_or_initialize_by(contact_data)
            contact.save(validate: false)
          end
        end
			else
				# render :json=> {:flag=> false, :error => patient.errors.full_messages.to_sentence }
      end
    end
		render :json=> {:flag=> true }
  end

	def import_billable_items
    @import_data = JSON.parse(File.read("public/import_files/#{@company.id}/bi.json"))
		@import_data.each do |import|
      item_data = serialize_item_data(import)
      if import['enateId'].include? "prod"
        item = Product.find_or_initialize_by(item_data)
      else
        item = BillableItem.find_or_initialize_by(item_data)
      end
      item.save(validate: false)
				# render :json=> {:flag=> false, :error => item.errors.full_messages.to_sentence }
				# break
    end
		import_item_inv_rel
  end

	def import_invoices
		PublicActivity.enabled = false
		payment_type =  @company.payment_types.find_by(name: 'Cash').id
    @import_data = JSON.parse(File.read("public/import_files/#{@company.id}/inv-#{@user.first_name}.json"))
    @import_data.each do |import|
      invoice_data = serialize_invoice_data(import)
      invoice = Invoice.find_or_initialize_by(invoice_data)
			Invoice.skip_callback(:save, :before, :generate_invoice_number)
      if invoice.save(validate: false)
        #save invoice user
        invoice_user_data = {}
        invoice_user_data['user_id'] = params[:user]
        invoice_user_data['invoice_id'] = invoice.id
        invoice_user = InvoicesUser.find_or_initialize_by(invoice_user_data)
        invoice_user.save(validate: false)

        #save invoice business
        invoice_business_data = {}
        invoice_business_data['invoice_id'] = invoice.id
        invoice_business_data['business_id'] = params[:business]
        invoice_business = BusinessesInvoice.find_or_initialize_by(invoice_business_data)
        invoice_business.save(validate: false)

        #save payments
        if import['amount_paid'].to_i > 0
          payment_data = {}
          payment_data['businessid'] = params[:business]
          payment_data['payment_date'] = invoice.close_date
          payment_data['patient_id'] = invoice.patient_id
          payment_data['creater_id'] = params[:user]
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
            business_payment_data['business_id'] = params[:business]
            business_payment_data['payment_id'] = payment.id
            business_payment = BusinessesPayment.find_or_initialize_by(business_payment_data)
            business_payment.save(validate: false)
          end
        end
			end
		end
		render :json=> {:flag=> true }
	end


	def import_item_inv_rel
		@import_data = JSON.parse(File.read("public/import_files/#{@company.id}/bti.json"))
		@import_data.each do |import|
			item_rel_data = serialize_item_rel_data(import)
			item_inv_rel = InvoiceItem.find_or_initialize_by(item_rel_data)
			item_inv_rel.save(validate: false)
		end
		render :json=> {:flag=> true}
	end

	def deleteimport
		DeleteEnateWorker.perform_async(@company.id,@user.id)
		# @import_data = JSON.parse(File.read('public/import_files/pat-drpoulin.json'))
    # @import_data.each do |import|
		# 	patients = Patient.find_by(enate_id: import['enateId'])
		# 	patient.destroy
		# end
	end

  private

  def serialize_invoice_dataenate(patient,user,balance,business)
    data = {}
    data['enate_id'] = '1234567890abcdef'
    data['issue_date'] = '2017-01-01'
    data['invoice_amount'] = balance
    data['subtotal'] = balance
    data['patientid'] = patient
    data['patient_id'] = patient
    data['creater_id'] = user
    data['creater_type'] = 'User'
    data['updater_id'] = user
    data['updater_type'] = 'User'
    data['businessid'] = business
    data
  end

	def find_doc
		@user = User.find_by(id: params[:user])
	end

	def serialize_patient_data_csv(patient_data)
		data={}
    data['first_name'] = patient_data['first_name']
    data['last_name'] = patient_data['last_name']
    data['gender'] = patient_data['gender']
    data['state'] = patient_data['state']
    data['city'] = patient_data['city']
    data['address'] = patient_data['address']
    data['postal_code'] = patient_data['postal_code']
    data['dob'] = patient_data['dob']
		data['notes'] = patient_data['notes']
		data['status'] = patient_data['status']
    data['company_id'] = @company.id
		return data
	end

  def serialize_patient_data(patient_data)
    data={}
    data['enate_id'] = patient_data['enateId']
    data['first_name'] = patient_data['firstName']
    data['last_name'] = patient_data['lastName']
    data['gender'] = patient_data['gender']
    data['country'] = patient_data['country']
    data['state'] = patient_data['state']
    data['city'] = patient_data['city']
    data['address'] = patient_data['street']
    data['occupation'] = patient_data['occupation']
    data['postal_code'] = patient_data['postal_code']
    data['emergency_contact'] = patient_data['emergency_contact']
    data['medicare_number'] = patient_data['medicare_number']
    data['age'] = patient_data['age']
    data['dob'] = patient_data['dob']
    data['email'] = patient_data['email']
    data['company_id'] = @company.id
    return data
  end

	def serialize_item_data(item_data)
    data={}
    data['enate_id'] = item_data['enateId']
		data['company_id'] = @company.id
    data['name'] = item_data['name']
    data['item_code'] = item_data['code']
    data['price'] = item_data['price']
    data['tax'] = item_data['tax']
    data['status'] = item_data['status'] if item_data['enateId'].include? "prod"
    return data
  end

  def serialize_invoice_data(invoice_data)
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
    data['creater_id'] = params[:user]
    data['creater_type'] = 'User'
    data['updater_id'] = params[:user]
    data['updater_type'] = 'User'
		data['businessid'] = params[:business]
    return data
  end


	def serialize_item_rel_data(inv_item_rel)
		data={}
		if inv_item_rel['enate_billable_item_id'].include? "prod"
			item = Product.find_by(enate_id: inv_item_rel['enate_billable_item_id'])
		else
			item = BillableItem.find_by(enate_id: inv_item_rel['enate_billable_item_id'])
		end
		invoice = Invoice.find_by(enate_id: inv_item_rel['enate_invoice_id'])
		data['item_id'] = item.id if item.present?
		data['item_type'] = item.class.to_s
		data['unit_price'] = inv_item_rel['price']
		data['quantity'] = inv_item_rel['quantity']
		data['total_price'] = inv_item_rel['price'].to_f * inv_item_rel['quantity'].to_i
		data['invoice_id'] = invoice.id if invoice.present?
		# data['enate_id'] = inv_item_rel['enateId']
		return data
	end
end
