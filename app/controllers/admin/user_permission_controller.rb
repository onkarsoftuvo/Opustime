class Admin::UserPermissionController < ApplicationController
  layout 'application_admin'
  before_action :admin_authorize
  before_filter :find_user_role_and_permission

  def index

    unless  current_owner.role.eql?('super_admin_user')
      # @permission_tab = @current_owner.user_role.admin_permission
    end
  end

  def apply_permission
    #  updates for admin users
    @user_permissions.each do |usr_permission|
      unless ['trial','permission','log'].include?(params[:module_name])
        attr , attr_name  = get_serialized_column(usr_permission , params[:module_name])
        attr[params[:col_name]] = params[:data][usr_permission.try(:user_role).try(:name)].to_bool
        usr_permission.update_attribute(attr_name.to_sym ,  attr)
      else
        attr , attr_name = simple_column(usr_permission , params[:module_name])
        usr_permission.update_attribute(attr_name.to_sym ,  params[:data][usr_permission.try(:user_role).try(:name)].to_bool)
      end

    end
    render :nothing=> true

  end

  private

  def find_user_role_and_permission
    admin_user_roles = UserRole.where(["name IN (?)", ADMIN_ROLE.values])
    @user_permissions = []
    admin_user_roles.each do |user_role|
      #  permission for admin user
      if user_role.admin_permission.nil?
        role_permission = user_role.create_admin_permission(business_report: {list: true , customer: true , earnbs: true , earnloc: true , financial: true },
                                                                        financial_report: {list: true , earn: true },
                                                                        trial_user: true ,
                                                                        notification: {business: true , user: true, email: true},
                                                                        subscription: {list: true , add: true},
                                                                        sms: {list: true , consm: true },
                                                                        others: {delete:true , bs: true , payment: true},
                                                                        permission: true ,
                                                                        logs: true)
      else
        role_permission = user_role.admin_permission
      end
      @user_permissions << role_permission
    end

  end

  def get_serialized_column(usr_permission , module_name)
    case module_name
      when 'business'
        return usr_permission.business_report ,  'business_report'
      when 'financial'
        return usr_permission.financial_report , 'financial_report'
      when 'notification'
        return usr_permission.notification , 'notification'
      when 'subscription'
        return usr_permission.subscription , 'subscription'
      when 'sms'
        return usr_permission.sms , 'sms'
      when 'import'
        return usr_permission.others , 'others'
    end
  end

  def simple_column(usr_permission , module_name)
    case module_name
      when 'trial'
        return usr_permission.trial_user , 'trial_user'
      when 'permission'
        return usr_permission.permission , 'permission'
      when 'log'
        return usr_permission.logs , 'logs'
    end
  end

end
