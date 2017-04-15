class ExpenseReportsController < ApplicationController
	respond_to :json
	before_filter :authorize
 	before_action :find_company_by_sub_domain
	before_action :check_authorization

 	skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

 	def index
 		result = {}
 		render :json => result

 	end

 	def get_categories
 		result = []
 		@company.expense_categories.each do |category|
 			item = {}
 			item[:name] = category.try(:name)
 			item[:value] = category.try(:name)
 			result << item
 		end
 		render :json => result
 	end

 	def listing
		result = {}
		result[:summary] = []
		result[:summary_total] = []
		result[:list] = []
		start_date = params[:start_date].to_date unless params[:start_date].nil?
		end_date = params[:end_date].to_date unless params[:end_date].nil?

		if params[:category] == "all"
			if start_date.nil? && end_date.nil?
				expenses = @company.expenses.active_expense.order("expenses.created_at desc")
			else
				expenses = @company.expenses.active_expense.order("expenses.created_at desc").where(["DATE(expenses.expense_date) >= ? AND DATE(expenses.expense_date) <= ?" , start_date , end_date ])
			end
			
		else
			if start_date.nil? && end_date.nil?
				expenses = @company.expenses.active_expense.joins(:expense_category).where(["expense_categories.name = ? " , params[:category]]).order("expenses.created_at desc")
			else
				expenses = 	@company.expenses.active_expense.joins(:expense_category).where(["expense_categories.name = ? " , params[:category]]).order("expenses.created_at desc").where(["DATE(expenses.expense_date) >= ? AND DATE(expenses.expense_date) <= ?" ,  start_date , end_date])
			end
			
		end

		# Expense lists category wise 
		expenses.each do |expense|
			item = {}
			item[:expense_id] = "0"*(6-expense.id.to_s.length)+ expense.id.to_s
			item[:date] = expense.expense_date.strftime("%d %b %Y")
			item[:vendor] = expense.try(:expense_vendor).try(:name)
			item[:category] = expense.expense_category.try(:name)
			item[:sub_total] = expense.sub_amount#.round(2)
			item[:tax] = expense.tax_amount#.round(2)
			item[:total] = expense.total_expense#.round(2)
			item[:notes] = expense.note
			result[:list] << item
		end
		

		# Getting summary details 
		expenses = expenses.group("category").select("expenses.id , category , SUM(sub_amount) sub_amount , SUM(tax_amount) tax_amount , SUM(total_expense) total_expense")
		total_amount_ex_tax = 0
		total_amount_tax = 0
		total_amount_inc_tax = 0
		flag = false
		expenses.each do |expense|
			item = {}
			item[:category] =  expense.expense_category.try(:name)
			item[:amount_ex_tax] = (expense.sub_amount.to_f ).round(2)
			item[:tax] = expense.tax_amount.to_f.round(2)
			item[:amount_inc_tax] = expense.total_expense.round(2)

			total_amount_ex_tax = total_amount_ex_tax + (expense.sub_amount.to_f )
			total_amount_tax = total_amount_tax + expense.tax_amount.to_f
			total_amount_inc_tax = total_amount_inc_tax + expense.total_expense.round(2)

			result[:summary] << item
			flag = true
		end

		# summary totals
		result[:summary_total] << {flag: flag ,  total_amount_ex_tax: total_amount_ex_tax.round(2) , total_amount_tax: total_amount_tax.round(2) , total_amount_inc_tax: total_amount_inc_tax.round(2) } 

 		render :json => result
 	end

 	def listing_export
 		result = {}
 		render  :json => result
	end

	private

	def check_authorization
		authorize! :manage , :expense_report
	end

end
