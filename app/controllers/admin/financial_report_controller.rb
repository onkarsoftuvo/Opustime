class Admin::FinancialReportController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :find_financial,  :only =>[:financial_bus_list, :financial_bus_earn]
  
  def financial_bus_list
    # @count = 0
     respond_to do |format|
       format.html
       format.json { render json: FinancialListDatatable.new(view_context) }
     end
  end
  
  def financial_bus_earn
    #@count = 0
    respond_to do |format|
      format.html
      format.json { render json: TopEarningBusinessDatatable.new(view_context) }
    end
  end

  def find_financial
    unless params[:project].nil?
      if params[:project].keys.include?"state"
        if params[:project][:state] == ""
          @company = Company.all
        else
          @company = Company.joins(:businesses).where(["businesses.state = ? OR businesses.city = ?  " ,"IN-" +  params[:project][:state],params[:project][:city]])
        end
      end
    else
      @company = Company.all 
    end
  end
  
end
