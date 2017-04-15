class Admin::ApprovalsController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :set_owner, except: [:index]

  def index
    respond_to do |format|
      format.html
      format.json { render json: UserDatatable.new(view_context) }
    end
  end

  def active_or_inactive
    if @owner.status
      @owner.update_column(:status, false)
      # AdminMailer.sidekiq_delay(:queue => 'admin').active_or_inactive(@owner.id) if @owner.update_column(:status, false)
      render :json => {:flag => true, :message => 'User inactivated successfully'}
    else
      @owner.update_column(:status, true)
      # AdminMailer.sidekiq_delay(:queue => 'admin').active_or_inactive(@owner.id) if  @owner.update_column(:status, true)
      render :json => {:flag => true, :message => 'User activated successfully'}
    end
  rescue
    render :json => {:flag => false, :message => 'Something went wrong...! '}
  end

  def destroy
    # AdminMailer.sidekiq_delay(:queue => 'admin').delete_account(@owner.id)
    @owner.destroy
    render :json => {:flag => true, :message => 'Admin user deleted successfully.'}
  rescue
    render :json => {:flag => false, :message => 'Something went wrong...! '}
  end

  private

  def set_owner
    @owner = Owner.find_by_id(params[:id])
  end

end
