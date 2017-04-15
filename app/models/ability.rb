class Ability
  include CanCan::Ability

  def initialize(user)

    # Making permission matrix dynamic
    
    user.user_role.permissions.each do |permission|
        can permission.action.to_sym, permission.subject_class.constantize
    end unless user.nil?

    user ||= User.new() # guest user (not logged in)

      can :check_security_role , [Appointment , Invoice ,Product , Contact , Expense , Communication , Payment , User, RecallType ]
      can :get_attendee , :all

      check_authorization_as_per_admin_for_report(ReportPermission.last , user.user_role.try(:name))
      check_authorization_as_per_admin_for_letter(LetterPermission.last , user.user_role.try(:name) , user)
      check_authorization_as_per_admin_for_tr_note(TreatnotePermission.last , user.user_role.try(:name) , user)
      check_authorization_as_per_admin_for_export(DataexportPermission.last , user.user_role.try(:name))
      check_authorization_as_per_admin_for_integration(SettingPermission.last , user.user_role.try(:name))
      check_authorization_as_per_admin_for_userinfo( UserinfoPermission.last, user.user_role.try(:name) , user)
      check_authorization_as_per_setting_module(user) unless user.new_record?
  end

  def check_authorization_as_per_admin_for_report(report_permission , u_role)
    (can :manage, :report if report_permission.report_apnt[u_role.to_sym].try(:to_bool)) unless report_permission.report_apnt.nil?
    (can :index, :patient_report if report_permission.report_upbday[u_role.to_sym].try(:to_bool)) unless report_permission.report_upbday.nil?
    (can :patients_without_upcoming_appnt, :patient_report if report_permission.report_pupapnt[u_role.to_sym].try(:to_bool)) unless report_permission.report_pupapnt.nil?
    (can :patient_listing, :patient_report if report_permission.report_totinvoice[u_role.to_sym].try(:to_bool)) unless report_permission.report_totinvoice.nil?
    (can :daily_payment, :daily_report if report_permission.report_dpay[u_role.to_sym].try(:to_bool)) unless report_permission.report_dpay.nil?
    (can :payment_summary , :payment_report if report_permission.report_pmt[u_role.to_sym].try(:to_bool)) unless report_permission.report_pmt.nil?
    (can :outstanding_invoice, :patient_report if report_permission.report_invoice[u_role.to_sym].try(:to_bool)) unless report_permission.report_invoice.nil?
    (can :practitioner_revenue , :practitioner_report if report_permission.report_prarevenue[u_role.to_sym].try(:to_bool)) unless report_permission.report_prarevenue.nil?
    (can :manage , :expense_report if report_permission.report_expense[u_role.to_sym].try(:to_bool)) unless report_permission.report_expense.nil?
    (can :recall_patient , :patient_report if report_permission.report_recall[u_role.to_sym].try(:to_bool)) unless report_permission.report_recall.nil?
    (can :refer , :refer_patient if report_permission.report_refersrc[u_role.to_sym].try(:to_bool)) unless report_permission.report_refersrc.nil?
  end

  def check_authorization_as_per_admin_for_letter(letter_permission , u_role , user)
    unless letter_permission.letter_viewall.nil?
      if letter_permission.letter_viewall[u_role].to_bool
        can [:manage , :manage_all] , Letter
      else
        unless letter_permission.latter_viewown.nil?
          if letter_permission.latter_viewown[u_role].to_bool
            can [:modify , :show , :manage_own], Letter
          end
        end
      end
    else
      unless letter_permission.latter_viewown.nil?
        if letter_permission.latter_viewown[u_role].to_bool
          can [:modify , :show , :manage_own], Letter
        end
      end
    end

    if (letter_permission.letter_delete.nil? || letter_permission.letter_delete[u_role].to_bool == false )
      cannot :destroy , Letter
    else
      can :destroy , Letter
    end
  end

  def check_authorization_as_per_admin_for_tr_note(tr_note_permission , u_role , user)

      company = user.company
      if tr_note_permission.treatnote_view.nil? || tr_note_permission.treatnote_view[u_role].to_bool == false
        cannot :view_own , TreatmentNote
      else
        can :view_own , TreatmentNote
        cannot :view_own , company.treatment_notes.active_treatment_note do |note|
          note.created_by_id.to_i != user.id
        end
      end

      if tr_note_permission.treatnote_viewall.nil? || tr_note_permission.treatnote_viewall[u_role].to_bool == false
        cannot :view_all , TreatmentNote
      else
        can :view_all , TreatmentNote
      end

      if tr_note_permission.edit_own.nil? || tr_note_permission.edit_own[u_role].to_bool == false
        cannot :edit_own , TreatmentNote
      else
        can :edit_own , TreatmentNote
        cannot :edit_own , company.treatment_notes.active_treatment_note do |note|
          note.created_by_id.to_i != user.id
        end
      end

      if (tr_note_permission.treatnote_delete.nil? || tr_note_permission.treatnote_delete[u_role].to_bool == false )
        cannot :delete , TreatmentNote
      else
        can :delete , TreatmentNote
      end


  end

  def check_authorization_as_per_admin_for_export(data_export_permission , u_role)
    if (data_export_permission.dataexport_allexprt.nil? || data_export_permission.dataexport_allexprt[u_role].to_bool == false )
      cannot :export , :other
    else
      can :export , :other
    end
  end

  def check_authorization_as_per_admin_for_integration(setting_permission , u_role)
    if (setting_permission.setting_ingrt.nil? || setting_permission.setting_ingrt[u_role].to_bool == false )
      cannot :manage , :integration
    else
      can :manage , :integration
    end
  end

  def check_authorization_as_per_admin_for_userinfo( userinfo_permission , u_role , user)
    if (userinfo_permission.userinfo_view.nil? || userinfo_permission.userinfo_view[u_role].to_bool == false )
      cannot :view_own ,  User
    else
      can :view_own , User
    end

    if (userinfo_permission.userinfo_edit.nil? || userinfo_permission.userinfo_edit[u_role].to_bool == false )
      cannot :edit_own , User
    else
      can :edit_own , User
    end

    if (userinfo_permission.userinfo_cru.nil? || userinfo_permission.userinfo_cru[u_role].to_bool == false )
      cannot :manage_other , User
    else
      can :manage_other , User
    end
  end

  def check_authorization_as_per_setting_module(user)
    if user.try(:user_role).try(:name).eql?(ROLE[2])
      account = user.company.try(:account)
      if account.try(:show_finance)

        cannot [:index, :patients_list , :new ,  :list_doctors , :products_list, :billable_item_list,
                :business_list , :show , :send_email_with_pdf , :invoice_print , :edit , :patient_detail , :update , :create , :destroy] , Invoice
        cannot [:index , :show , :payment_print , :new , :avail_payment_types , :create ,
                  :patient_outstanding_invoices , :edit , :update , :destroy] , Payment
        cannot [:index , :edit , :new , :create ,:update , :destroy] , Product
        cannot [:index , :categories_list_from_model , :vendors_list_from_model , :product_list , :edit , :new , :create , :update , :destroy ] , Expense
      end

    end




  end

end


