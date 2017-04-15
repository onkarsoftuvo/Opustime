class Admin::AdminNotificationController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :find_business , :only =>[:business_notification, :user_notification]
  
  # def business_notification
  #
  # end
  
  # def user_notification
  #   @count = 0
  # end
  
  # def email_notification
  #   @count = 0
  # end
  
  def find_business
    @company = Company.all.order('created_at desc')
  end
  
end
