class Admin::DashboardsController < ApplicationController
  layout 'application_admin'
  before_action :admin_authorize
  before_action :find_company

  def home

  end

  private

  def find_company
    @company = Company.all
  end


end
