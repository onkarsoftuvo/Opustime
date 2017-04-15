class Admin::AdminProfilesController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :find_owner

  def edit
  end

  def update
    mass_assignment = params[:owner][:password].present? ? owner_params : owner_params.except!(:password, :password_confirmation)
    respond_to do |format|
      if @owner.update(mass_assignment)
        format.html { redirect_to :back , :flash => {:success=>'Profile successfully updated.'}  }
      else
        format.html { redirect_to :back, :flash => {:error=>@owner.errors.full_messages.to_sentence}  }
      end
    end
  end



  private

  def owner_params
    params.require(:owner).permit(:first_name, :last_name,:logo, :email, :password, :password_confirmation)
  end

  def find_owner
    @owner = current_owner
  end
end
