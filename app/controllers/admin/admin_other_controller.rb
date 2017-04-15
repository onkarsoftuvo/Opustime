class Admin::AdminOtherController < ApplicationController
	layout "application_admin"
	before_action :admin_authorize
	before_filter :find_company
	def import_delete_request
		@import = Import.all.order(['created_at desc '])
	end

	def import_destroy
		puts 'Hey'
		import = Import.find(params[:id])
		import.delete_associated_records
		import.destroy
		redirect_to :back , :notice=>'Import has successfully deleted!'

	end

	def business_subscription
		respond_to do |format|
			format.html
			format.json { render json: BusinessSubscriptionDatatable.new(view_context) }
		end
	end

	def business_payments
		respond_to do |format|
			format.html
			format.json { render json: BusinessPaymentDatatable.new(view_context) }
		end
	end

	def subscription_history
		respond_to do |format|
			format.html
			format.json { render json: SubscriptionHistoryDatatable.new(view_context,params[:id]) }
		end
	end

	def payment_history
		respond_to do |format|
			format.html
			format.json { render json: PaymentHistoryDatatable.new(view_context,params[:id]) }
		end
	end

	private
    
	def find_company
		@company = Company.all 
	end

end
