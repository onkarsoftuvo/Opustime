class Admin::TrialUserController < ApplicationController
  include Opustime::Utility
  layout "application_admin"
  before_action :admin_authorize
  # before_action :find_business, :only => [:trial_user]
  before_action :set_company, :only => [:extend_trial]

  def trial_user
    # @count = 0
    # @comp =Company.joins(:subscription).where('subscriptions.is_subscribed =?', false)
    respond_to do |format|
      format.html
      format.json { render json: TrialUserDatatable.new(view_context) }
    end
  end

  # def find_business
  #   @company = Company.all
  # end

  def extend_trial
    if params[:days].present? && params[:days].to_i > 0
      @comp.subscription.update_columns(:end_date => @comp.subscription.end_date+params[:days].to_i);
      remaining_days = total_days(@comp.subscription.end_date, Time.now.to_date)
      render :json => {:flag => true, :remaining_days => remaining_days, :extended_end_date => @comp.subscription.end_date.strftime('%A, %d %b %Y %l:%M %p')}
    else
      render :json => {:flag => false, :message => 'invalid days'}
    end

  end

  private

  def set_company
    @comp = Company.find_by_id(params[:id])
  end

end
