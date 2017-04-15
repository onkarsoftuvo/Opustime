class Admin::PermissionController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :find_business, :only=>[:admin_permission]
  
  def admin_permission
    @dashboard_permission = @current_owner.dashboard_permission
  	@apnt_permission = @current_owner.appointment_permission
    @patient_permission = @current_owner.patient_permission
    @pntfile_permission = @current_owner.pntfile_permission
    @invoice_permission = @current_owner.invoice_permission
    @product_permission = @current_owner.product_permission
    @payment_permission = @current_owner.payment_permission
    @expense_permission = @current_owner.expense_permission
    @contact_permission = @current_owner.contact_permission
    @announcemsg_permission = @current_owner.announcemsg_permission
    @userinfo_permission = @current_owner.userinfo_permission
    @communication_permission = @current_owner.communication_permission
    @medical_permission = @current_owner.medical_permission
    @treatnote_permission = @current_owner.treatnote_permission
    @letter_permission = @current_owner.letter_permission
    @recall_permission = @current_owner.recall_permission
    @report_permission = @current_owner.report_permission
    @dataexport_permission = @current_owner.dataexport_permission
    @setting_permission = @current_owner.setting_permission

  end

  def dashboard
    if params[:col_name].eql?'top'
      if @current_owner.dashboard_permission
        @current_owner.dashboard_permission.update_attributes(dashboard_top: params[:data])
      else
        @current_owner.create_dashboard_permission(dashboard_top: params[:data])
      end

    elsif params[:col_name].eql?'report'
      if @current_owner.dashboard_permission
        @current_owner.dashboard_permission.update_attributes(dashboard_report: params[:data])
      else
        @current_owner.create_dashboard_permission(dashboard_report: params[:data])
      end
    elsif params[:col_name].eql?'appnt'
      if @current_owner.dashboard_permission
        @current_owner.dashboard_permission.update_attributes(dashboard_appnt: params[:data])
      else
        @current_owner.create_dashboard_permission(dashboard_appnt: params[:data])
      end
    elsif params[:col_name].eql?'activity'
      if @current_owner.dashboard_permission
        @current_owner.dashboard_permission.update_attributes(dashboard_activity: params[:data])
      else
        @current_owner.create_dashboard_permission(dashboard_activity: params[:data])
      end
    elsif params[:col_name].eql?'chartpracti'
      if @current_owner.dashboard_permission
        @current_owner.dashboard_permission.update_attributes(dashboard_chartpracti: params[:data])
      else
        @current_owner.create_dashboard_permission(dashboard_chartpracti: params[:data])
      end
    elsif params[:col_name].eql?'chartproduct'
      if @current_owner.dashboard_permission
        @current_owner.dashboard_permission.update_attributes(dashboard_chartproduct: params[:data])
      else
        @current_owner.create_dashboard_permission(dashboard_chartproduct: params[:data])
      end
    end
    respond_to do |format|
      format.html
      format.js
    end

  end


  def create
  	if params[:col_name].eql? "view"
  		if @current_owner.appointment_permission
  			@current_owner.appointment_permission.update_attributes(apnt_view: params[:data])
  		else
			  @current_owner.create_appointment_permission(apnt_view: params[:data])
      end

    elsif params[:col_name].eql? "create"
      if @current_owner.appointment_permission
          @current_owner.appointment_permission.update_attributes(apnt_create: params[:data])
        else
        @current_owner.create_appointment_permission(apnt_create: params[:data])
        end
    elsif params[:col_name].eql? "edit"
      if @current_owner.appointment_permission
          @current_owner.appointment_permission.update_attributes(apnt_edit: params[:data])
        else
        @current_owner.create_appointment_permission(apnt_edit: params[:data])
        end
    elsif params[:col_name].eql? "delete"
      if @current_owner.appointment_permission
        @current_owner.appointment_permission.update_attributes(apnt_delete: params[:data])
      else
        @current_owner.create_appointment_permission(apnt_delete: params[:data])
      end
    end
    name, cancan_action = eval_cancan_action(params[:col_name] , "Appointment")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "Appointment" , act_name  , name )
    end

  	respond_to do |format|
  		format.html
  		format.js
  	end
  end

  def patient_create
    if params[:col_name].eql? "view"
      if @current_owner.patient_permission
        @current_owner.patient_permission.update_attributes(patient_view: params[:data])
      else
        @current_owner.create_patient_permission(patient_view: params[:data])
      end
    elsif params[:col_name].eql? "create"
      if @current_owner.patient_permission
        @current_owner.patient_permission.update_attributes(patient_create: params[:data])
      else
        @current_owner.create_patient_permission(patient_create: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.patient_permission
        @current_owner.patient_permission.update_attributes(patient_edit: params[:data])
      else
        @current_owner.create_patient_permission(patient_edit: params[:data])
      end
    elsif params[:col_name].eql? "sms"
      if @current_owner.patient_permission
        @current_owner.patient_permission.update_attributes(patient_sms: params[:data])
      else
        @current_owner.create_patient_permission(patient_sms: params[:data])
      end
    elsif params[:col_name].eql? "archive"
      if @current_owner.patient_permission
        @current_owner.patient_permission.update_attributes(patient_archive: params[:data])
      else
        @current_owner.create_patient_permission(patient_archive: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.patient_permission
        @current_owner.patient_permission.update_attributes(patient_delete: params[:data])
      else
        @current_owner.create_patient_permission(patient_delete: params[:data])
      end
    end

    name, cancan_action = eval_cancan_action(params[:col_name] , "Patient")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "Patient" , act_name  , name )
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def pntfile_create
    if params[:col_name].eql? "upload"
      if @current_owner.pntfile_permission
        @current_owner.pntfile_permission.update_attributes(pntfile_upload: params[:data])
      else
        @current_owner.create_pntfile_permission(pntfile_upload: params[:data])
      end
      write_permission(params[:data] , 'FileAttachment' , 'upload'   , 'upload' )
    elsif params[:col_name].eql? "viewname"
      if @current_owner.pntfile_permission
        @current_owner.pntfile_permission.update_attributes(pntfile_viewname: params[:data])
      else
        @current_owner.create_pntfile_permission(pntfile_viewname: params[:data])
      end
      ['viewname'].each do |action_name|
        write_permission(params[:data] , 'FileAttachment' , action_name   , 'viewname')
      end

    elsif params[:col_name].eql? "view"
      if @current_owner.pntfile_permission
        @current_owner.pntfile_permission.update_attributes(pntfile_view: params[:data])
      else
        @current_owner.create_pntfile_permission(pntfile_view: params[:data])
      end
      ['viewfile'].each do |action_name|
        write_permission(params[:data] , 'FileAttachment' , action_name   , 'view')
      end
    elsif params[:col_name].eql? "update"
      if @current_owner.pntfile_permission
        @current_owner.pntfile_permission.update_attributes(pntfile_update: params[:data])
      else
        @current_owner.create_pntfile_permission(pntfile_update: params[:data])
      end
      ['edit' , 'update'].each do |action_name|
        write_permission(params[:data] , 'FileAttachment' , action_name   , 'update')
      end
    elsif params[:col_name].eql? "delown"
      if @current_owner.pntfile_permission
        @current_owner.pntfile_permission.update_attributes(pntfile_delown: params[:data])
      else
        @current_owner.create_pntfile_permission(pntfile_delown: params[:data])
      end
      ['delown'].each do |action_name|
        write_permission(params[:data] , 'FileAttachment' , action_name   , 'delete')
      end
    elsif params[:col_name].eql? "delall"
      if @current_owner.pntfile_permission
        @current_owner.pntfile_permission.update_attributes(pntfile_delall: params[:data])
      else
        @current_owner.create_pntfile_permission(pntfile_delall: params[:data])
      end
      ['delall'].each do |action_name|
        write_permission(params[:data] , 'FileAttachment' , action_name   , 'delete')
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def announcemsg_create
    if params[:col_name].eql? "crud"
      if @current_owner.announcemsg_permission
        @current_owner.announcemsg_permission.update_attributes(announcemsg_crud: params[:data])
      else
        @current_owner.create_announcemsg_permission(announcemsg_crud: params[:data])
      end
    elsif params[:col_name].eql? "comment"
      if @current_owner.announcemsg_permission
        @current_owner.announcemsg_permission.update_attributes(announcemsg_comment: params[:data])
      else
        @current_owner.create_announcemsg_permission(announcemsg_comment: params[:data])
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def userinfo_create
    if params[:col_name].eql? "view"
      if @current_owner.userinfo_permission
        @current_owner.userinfo_permission.update_attributes(userinfo_view: params[:data])
      else
        @current_owner.create_userinfo_permission(userinfo_view: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.userinfo_permission
        @current_owner.userinfo_permission.update_attributes(userinfo_edit: params[:data])
      else
        @current_owner.create_userinfo_permission(userinfo_edit: params[:data])
      end
    elsif params[:col_name].eql? "cru"
      if @current_owner.userinfo_permission
        @current_owner.userinfo_permission.update_attributes(userinfo_cru: params[:data])
      else
        @current_owner.create_userinfo_permission(userinfo_cru: params[:data])
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end


  def invoice_create
    if params[:col_name].eql? "view"
      if @current_owner.invoice_permission
        @current_owner.invoice_permission.update_attributes(invoice_view: params[:data])
      else
        @current_owner.create_invoice_permission(invoice_view: params[:data])
      end
    elsif params[:col_name].eql? "create"
      if @current_owner.invoice_permission
        @current_owner.invoice_permission.update_attributes(invoice_create: params[:data])
      else
        @current_owner.create_invoice_permission(invoice_create: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.invoice_permission
        @current_owner.invoice_permission.update_attributes(invoice_edit: params[:data])
      else
        @current_owner.create_invoice_permission(invoice_edit: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.invoice_permission
        @current_owner.invoice_permission.update_attributes(invoice_delete: params[:data])
      else
        @current_owner.create_invoice_permission(invoice_delete: params[:data])
      end
    end

    name, cancan_action = eval_cancan_action(params[:col_name] , "Invoice")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "Invoice" , act_name  , name )
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def payment_create
    if params[:col_name].eql? "view"
      if @current_owner.payment_permission
        @current_owner.payment_permission.update_attributes(payment_view: params[:data])
      else
        @current_owner.create_payment_permission(payment_view: params[:data])
      end
    elsif params[:col_name].eql? "create"
      if @current_owner.payment_permission
        @current_owner.payment_permission.update_attributes(payment_create: params[:data])
      else
        @current_owner.create_payment_permission(payment_create: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.payment_permission
        @current_owner.payment_permission.update_attributes(payment_edit: params[:data])
      else
        @current_owner.create_payment_permission(payment_edit: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.payment_permission
        @current_owner.payment_permission.update_attributes(payment_delete: params[:data])
      else
        @current_owner.create_payment_permission(payment_delete: params[:data])
      end
    end
    name, cancan_action = eval_cancan_action(params[:col_name] , "Payment")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "Payment" , act_name  , name )
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def product_create
    if params[:col_name].eql? "view"
      if @current_owner.product_permission
        @current_owner.product_permission.update_attributes(product_view: params[:data])
      else
        @current_owner.create_product_permission(product_view: params[:data])
      end
      write_permission(params[:data] , "ProductStock" , 'index'  , 'view')
    elsif params[:col_name].eql? "create"
      if @current_owner.product_permission
        @current_owner.product_permission.update_attributes(product_create: params[:data])
      else
        @current_owner.create_product_permission(product_create: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.product_permission
        @current_owner.product_permission.update_attributes(product_edit: params[:data])
      else
        @current_owner.create_product_permission(product_edit: params[:data])
      end
    elsif params[:col_name].eql? "stock"
      if @current_owner.product_permission
        @current_owner.product_permission.update_attributes(product_stock: params[:data])
      else
        @current_owner.create_product_permission(product_stock: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.product_permission
        @current_owner.product_permission.update_attributes(product_delete: params[:data])
      else
        @current_owner.create_product_permission(product_delete: params[:data])
      end
    end
    name, cancan_action = eval_cancan_action(params[:col_name] , "Product")
    unless params[:col_name].eql?('stock')
      cancan_action.each do |act_name|
        write_permission(params[:data] , "Product" , act_name  , name )
      end
    else
      cancan_action.each do |act_name|
        write_permission(params[:data] , "ProductStock" , act_name  , name )
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def expense_create
    if params[:col_name].eql? "view"
      if @current_owner.expense_permission
        @current_owner.expense_permission.update_attributes(expense_view: params[:data])
      else
        @current_owner.create_expense_permission(expense_view: params[:data])
      end
    elsif params[:col_name].eql? "create"
      if @current_owner.expense_permission
        @current_owner.expense_permission.update_attributes(expense_create: params[:data])
      else
        @current_owner.create_expense_permission(expense_create: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.expense_permission
        @current_owner.expense_permission.update_attributes(expense_edit: params[:data])
      else
        @current_owner.create_expense_permission(expense_edit: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.expense_permission
        @current_owner.expense_permission.update_attributes(expense_delete: params[:data])
      else
        @current_owner.create_expense_permission(expense_delete: params[:data])
      end
    end
    name, cancan_action = eval_cancan_action(params[:col_name] , "Expense")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "Expense" , act_name  , name )
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def contact_create
    if params[:col_name].eql? "view"
      if @current_owner.contact_permission
        @current_owner.contact_permission.update_attributes(contact_view: params[:data])
      else
        @current_owner.create_contact_permission(contact_view: params[:data])
      end
    elsif params[:col_name].eql? "create"
      if @current_owner.contact_permission
        @current_owner.contact_permission.update_attributes(contact_create: params[:data])
      else
        @current_owner.create_contact_permission(contact_create: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.contact_permission
        @current_owner.contact_permission.update_attributes(contact_edit: params[:data])
      else
        @current_owner.create_contact_permission(contact_edit: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.contact_permission
        @current_owner.contact_permission.update_attributes(contact_delete: params[:data])
      else
        @current_owner.create_contact_permission(contact_delete: params[:data])
      end
    end
    name, cancan_action = eval_cancan_action(params[:col_name] , "Contact")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "Contact" , act_name  , name )
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def communication_create
    if params[:col_name].eql? "view"
      if @current_owner.communication_permission
        @current_owner.communication_permission.update_attributes(communication_view: params[:data])
      else
        @current_owner.create_communication_permission(communication_view: params[:data])
      end
    end
    name, cancan_action = eval_cancan_action(params[:col_name] , "Communication")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "Communication" , act_name  , name )
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def medical_create
    if params[:col_name].eql? "crud"
      if @current_owner.medical_permission
        @current_owner.medical_permission.update_attributes(medical_crud: params[:data])
      else
        @current_owner.create_medical_permission(medical_crud: params[:data])
      end
    end
    name, cancan_action = eval_cancan_action(params[:col_name] , "MedicalAlert")
    cancan_action.each do |act_name|
      write_permission(params[:data] , "MedicalAlert" , act_name  , name )
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def treatnote_create
    if params[:col_name].eql? "view"
      if @current_owner.treatnote_permission
        @current_owner.treatnote_permission.update_attributes(treatnote_view: params[:data])
      else
        @current_owner.create_treatnote_permission(treatnote_view: params[:data])
      end
    elsif params[:col_name].eql? "viewall"
      if @current_owner.treatnote_permission
        @current_owner.treatnote_permission.update_attributes(treatnote_viewall: params[:data])
      else
        @current_owner.create_treatnote_permission(treatnote_viewall: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.treatnote_permission
        @current_owner.treatnote_permission.update_attributes(edit_own: params[:data])
      else
        @current_owner.create_treatnote_permission(edit_own: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.treatnote_permission
        @current_owner.treatnote_permission.update_attributes(treatnote_delete: params[:data])
      else
        @current_owner.create_treatnote_permission(treatnote_delete: params[:data])
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def letter_create
    if params[:col_name].eql? 'viewown'
      if @current_owner.letter_permission
        @current_owner.letter_permission.update_attributes(latter_viewown: params[:data])
      else
        @current_owner.create_letter_permission(latter_viewown: params[:data])
      end
    elsif params[:col_name].eql? 'viewall'
      if @current_owner.letter_permission
        @current_owner.letter_permission.update_attributes(letter_viewall: params[:data])
      else
        @current_owner.create_letter_permission(letter_viewall: params[:data])
      end
    elsif params[:col_name].eql? 'delete'
      if @current_owner.letter_permission
        @current_owner.letter_permission.update_attributes(letter_delete: params[:data])
      else
        @current_owner.create_letter_permission(letter_delete: params[:data])
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def recall_create
    if params[:col_name].eql? "add"
      if @current_owner.recall_permission
        @current_owner.recall_permission.update_attributes(recall_add: params[:data])
      else
        @current_owner.create_recall_permission(recall_add: params[:data])
      end
    elsif params[:col_name].eql? "edit"
      if @current_owner.recall_permission
        @current_owner.recall_permission.update_attributes(recall_edit: params[:data])
      else
        @current_owner.create_recall_permission(recall_edit: params[:data])
      end
    elsif params[:col_name].eql? "delete"
      if @current_owner.recall_permission
        @current_owner.recall_permission.update_attributes(recall_delete: params[:data])
      else
        @current_owner.create_recall_permission(recall_delete: params[:data])
      end
    elsif params[:col_name].eql? "addpnt"
      if @current_owner.recall_permission
        @current_owner.recall_permission.update_attributes(recall_addpnt: params[:data])
      else
        @current_owner.create_recall_permission(recall_addpnt: params[:data])
      end
    elsif params[:col_name].eql? "editpnt"
      if @current_owner.recall_permission
        @current_owner.recall_permission.update_attributes(recall_editpnt: params[:data])
      else
        @current_owner.create_recall_permission(recall_editpnt: params[:data])
      end
    elsif params[:col_name].eql? "deletepnt"
      if @current_owner.recall_permission
        @current_owner.recall_permission.update_attributes(recall_deletepnt: params[:data])
      else
        @current_owner.create_recall_permission(recall_deletepnt: params[:data])
      end
    elsif params[:col_name].eql? "markpnt"
      if @current_owner.recall_permission
        @current_owner.recall_permission.update_attributes(recall_markpnt: params[:data])
      else
        @current_owner.create_recall_permission(recall_markpnt: params[:data])
      end
    end
    contlr_name = params[:col_name].include?('pnt') ?  'Recall' : 'RecallType'

    name, cancan_action = eval_cancan_action(params[:col_name] , contlr_name)
    cancan_action.each do |act_name|
      write_permission(params[:data] , contlr_name , act_name  , name )
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def report_create
    if params[:col_name].eql? "apnt"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_apnt: params[:data])
      else
        @current_owner.create_report_permission(report_apnt: params[:data])
      end
    elsif params[:col_name].eql? "missapnt"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_missapnt: params[:data])
      else
        @current_owner.create_report_permission(report_missapnt: params[:data])
      end
    elsif params[:col_name].eql? "upbday"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_upbday: params[:data])
      else
        @current_owner.create_report_permission(report_upbday: params[:data])
      end
    elsif params[:col_name].eql? "pupapnt"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_pupapnt: params[:data])
      else
        @current_owner.create_report_permission(report_pupapnt: params[:data])
      end
    elsif params[:col_name].eql? "totinvoice"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_totinvoice: params[:data])
      else
        @current_owner.create_report_permission(report_totinvoice: params[:data])
      end
    elsif params[:col_name].eql? "dpay"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_dpay: params[:data])
      else
        @current_owner.create_report_permission(report_dpay: params[:data])
      end
    elsif params[:col_name].eql? "pmt"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_pmt: params[:data])
      else
        @current_owner.create_report_permission(report_pmt: params[:data])
      end
    elsif params[:col_name].eql? "invoice"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_invoice: params[:data])
      else
        @current_owner.create_report_permission(report_invoice: params[:data])
      end
    elsif params[:col_name].eql? "revenue"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_revenue: params[:data])
      else
        @current_owner.create_report_permission(report_revenue: params[:data])
      end
    elsif params[:col_name].eql? "prarevenue"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_prarevenue: params[:data])
      else
        @current_owner.create_report_permission(report_prarevenue: params[:data])
      end
    elsif params[:col_name].eql? "expense"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_expense: params[:data])
      else
        @current_owner.create_report_permission(report_expense: params[:data])
      end
    elsif params[:col_name].eql? "recall"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_recall: params[:data])
      else
        @current_owner.create_report_permission(report_recall: params[:data])
      end
    elsif params[:col_name].eql? "refersrc"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_refersrc: params[:data])
      else
        @current_owner.create_report_permission(report_refersrc: params[:data])
      end
    elsif params[:col_name].eql? "pntmarket"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_pntmarket: params[:data])
      else
        @current_owner.create_report_permission(report_pntmarket: params[:data])
      end
    elsif params[:col_name].eql? "apntmarket"
      if @current_owner.report_permission
        @current_owner.report_permission.update_attributes(report_apntmarket: params[:data])
      else
        @current_owner.create_report_permission(report_apntmarket: params[:data])
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def dataexport_create
    if params[:col_name].eql? "prod"
      if @current_owner.dataexport_permission
        @current_owner.dataexport_permission.update_attributes(dataexport_prod: params[:data])
      else
        @current_owner.create_dataexport_permission(dataexport_prod: params[:data])
      end
      write_permission(params[:data] , 'Product' , 'export'  , 'product' )
    elsif params[:col_name].eql? "invoice"
      if @current_owner.dataexport_permission
        @current_owner.dataexport_permission.update_attributes(dataexport_invoice: params[:data])
      else
        @current_owner.create_dataexport_permission(dataexport_invoice: params[:data])
      end
      write_permission(params[:data] , 'Invoice' , 'export'  , 'invoice' )
    elsif params[:col_name].eql? "pmt"
      if @current_owner.dataexport_permission
        @current_owner.dataexport_permission.update_attributes(dataexport_pmt: params[:data])
      else
        @current_owner.create_dataexport_permission(dataexport_pmt: params[:data])
      end
      write_permission(params[:data] , 'Payment' , 'export'  , 'payment')
    elsif params[:col_name].eql? "expns"
      if @current_owner.dataexport_permission
        @current_owner.dataexport_permission.update_attributes(dataexport_expns: params[:data])
      else
        @current_owner.create_dataexport_permission(dataexport_expns: params[:data])
      end
      write_permission(params[:data] , 'Expense' , 'export'  , 'expense')
    elsif params[:col_name].eql? "allexprt"
      if @current_owner.dataexport_permission
        @current_owner.dataexport_permission.update_attributes(dataexport_allexprt: params[:data])
      else
        @current_owner.create_dataexport_permission(dataexport_allexprt: params[:data])
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def setting_create
    if params[:col_name].eql? 'import'
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_import: params[:data])
      else
        @current_owner.create_setting_permission(setting_import: params[:data])
      end
      write_permission(params[:data] ,'Import', 'manage' , 'import')
    elsif params[:col_name].eql? 'acnt'
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_acnt: params[:data])
      else
        @current_owner.create_setting_permission(setting_acnt: params[:data])
      end
      write_permission(params[:data] ,'Account', 'manage' , 'account')
    elsif params[:col_name].eql? "apntrem"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_apntrem: params[:data])
      else
        @current_owner.create_setting_permission(setting_apntrem: params[:data])
      end
      write_permission(params[:data] ,'AppointmentReminder', 'manage' , 'apntrem')
    elsif params[:col_name].eql? "apnttype"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_apnttype: params[:data])
      else
        @current_owner.create_setting_permission(setting_apnttype: params[:data])
      end
      write_permission(params[:data] ,'AppointmentType', 'manage' , 'apnttype')
    elsif params[:col_name].eql? "bill"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_bill: params[:data])
      else
        @current_owner.create_setting_permission(setting_bill: params[:data])
      end
      write_permission(params[:data] ,'BillableItem', 'manage' , 'bill')
    elsif params[:col_name].eql? "bsn"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_bsn: params[:data])
      else
        @current_owner.create_setting_permission(setting_bsn: params[:data])
      end
      write_permission(params[:data] ,'Business', 'manage' , 'bsn')
    elsif params[:col_name].eql? "onbook"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_onbook: params[:data])
      else
        @current_owner.create_setting_permission(setting_onbook: params[:data])
      end
      write_permission(params[:data] ,'OnlineBooking', 'manage' , 'onbook')
    elsif params[:col_name].eql? "cns"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_cns: params[:data])
      else
        @current_owner.create_setting_permission(setting_cns: params[:data])
      end
      write_permission(params[:data] ,'Concession', 'manage' , 'cns')
    elsif params[:col_name].eql? "docprint"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_docprint: params[:data])
      else
        @current_owner.create_setting_permission(setting_docprint: params[:data])
      end
      write_permission(params[:data] ,'DocumentAndPrinting', 'manage' , 'docprint')
    elsif params[:col_name].eql? "ingrt"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_ingrt: params[:data])
      else
        @current_owner.create_setting_permission(setting_ingrt: params[:data])
      end

    elsif params[:col_name].eql? "invcset"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_invcset: params[:data])
      else
        @current_owner.create_setting_permission(setting_invcset: params[:data])
      end
      write_permission(params[:data] ,'InvoiceSetting', 'manage' , 'invcset')
    elsif params[:col_name].eql? "lettemp"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_lettemp: params[:data])
      else
        @current_owner.create_setting_permission(setting_lettemp: params[:data])
      end
      write_permission(params[:data] ,'LetterTemplate', 'manage' , 'lettemp')
    elsif params[:col_name].eql? "smstemp"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_smstemp: params[:data])
      else
        @current_owner.create_setting_permission(setting_smstemp: params[:data])
      end
      write_permission(params[:data] ,'SmsTemplate', 'manage' , 'smstemp')
    elsif params[:col_name].eql? "pmttype"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_pmttype: params[:data])
      else
        @current_owner.create_setting_permission(setting_pmttype: params[:data])
      end
      write_permission(params[:data] ,'PaymentType', 'manage' , 'pmttype')
    elsif params[:col_name].eql? "refsrc"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_refsrc: params[:data])
      else
        @current_owner.create_setting_permission(setting_refsrc: params[:data])
      end
      write_permission(params[:data] ,'ReferralType', 'manage' , 'refsrc')
    elsif params[:col_name].eql? "smsset"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_smsset: params[:data])
      else
        @current_owner.create_setting_permission(setting_smsset: params[:data])
      end
      write_permission(params[:data] ,'SmsSetting', 'manage' , 'smsset')
    elsif params[:col_name].eql? "sub"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_sub: params[:data])
      else
        @current_owner.create_setting_permission(setting_sub: params[:data])
      end
      write_permission(params[:data] ,'Subscription', 'manage' , 'sub')
    elsif params[:col_name].eql? "tax"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_tax: params[:data])
      else
        @current_owner.create_setting_permission(setting_tax: params[:data])
      end
      write_permission(params[:data] ,'TaxSetting', 'manage' , 'tax')
    elsif params[:col_name].eql? "tnt"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_tnt: params[:data])
      else
        @current_owner.create_setting_permission(setting_tnt: params[:data])
      end
      write_permission(params[:data] ,'TemplateNote', 'manage' , 'tnt')
    elsif params[:col_name].eql? "userpract"
      if @current_owner.setting_permission
        @current_owner.setting_permission.update_attributes(setting_userpract: params[:data])
      else
        @current_owner.create_setting_permission(setting_userpract: params[:data])
      end
      write_permission(params[:data] ,'User', 'index' , 'userpract')
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def find_business
    @company = Company.all
  end



  private

  def write_permission(roles_data , sub_class , action_name , name)
      roles_data.each do |k,v|
        role = UserRole.find_by_name(k)
        if v.eql?'true'
          permission = role.permissions.where(["subject_class = ? and action = ?", sub_class, action_name]).first
          unless permission
            permission = role.permissions.new
            permission.name = name
            permission.subject_class = sub_class
            permission.action = action_name
            permission.save
          end
        else
          permission = role.permissions.where(["subject_class = ? and action = ?", sub_class, action_name]).first
          permission.destroy unless permission.nil?
        end
      end
  end

  def eval_cancan_action(action , controller_name)
    name = action.to_s
    cancan_action = action_list(action , controller_name )
    return name, cancan_action
  end

  def action_list(myaction , controller_name)
    if controller_name.eql? "Appointment"
      case myaction.to_s
        when "view"
          cancan_action = %w(index show new calendar_setting location_wise_available_doctors get_appointments_in_time_period practitioner_wise_appointment_types practitioners_availability view_logs )
        when  "create"
          cancan_action = %w(create check_practitioner_availability_for_specific_day_and_time_on_a_location)
        when "edit"
          cancan_action = %w(edit  update update_partially )
        when "delete"
          cancan_action = %w(destroy)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "Patient"
      case myaction.to_s
        when 'view'
          cancan_action = %w(user_role_wise_authority index get_patient_submodules_total clients_modules show account_history account_statement  account_statement_pdf send_email)
        when  'create'
          cancan_action = %w(create list_contact doctors_list list_related_patients new)
        when 'edit'
          cancan_action = %w(edit update identical patient_merge)
        when 'delete'
          cancan_action = %w(permanent_delete)
        when 'sms'
          cancan_action = %w(send_sms )
        when 'archive'
          cancan_action = %w(destroy status_active)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "Contact"
      case myaction.to_s
        when "view"
          cancan_action = %w(index edit)
        when  "create"
          cancan_action = %w(create)
        when "edit"
          cancan_action = %w(update)
        when "delete"
          cancan_action = %w(destroy)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "Invoice"
      case myaction.to_s
        when "view"
          cancan_action = %w(index patients_list new list_doctors products_list billable_item_list business_list show send_email_with_pdf invoice_print)
        when  "create"
          cancan_action = %w(create)
        when "edit"
          cancan_action = %w(edit patient_detail update)
        when "delete"
          cancan_action = %w(destroy)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "Payment"
      case myaction.to_s
        when "view"
          cancan_action = %w(index show payment_print)
        when  "create"
          cancan_action = %w(new avail_payment_types create patient_outstanding_invoices)
        when "edit"
          cancan_action = %w(edit update)
        when "delete"
          cancan_action = %w(destroy)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "Product"
      case myaction.to_s
        when "view"
          cancan_action = %w(index edit)
        when  "create"
          cancan_action = %w(new create  )
        when "edit"
          cancan_action = %w(update)
        when "delete"
          cancan_action = %w(destroy)
        when "stock"
          cancan_action = %w(create)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "Expense"
      case myaction.to_s
        when "view"
          cancan_action = %w(index categories_list_from_model vendors_list_from_model product_list edit)
        when  "create"
          cancan_action = %w(new create )
        when "edit"
          cancan_action = %w(update)
        when "delete"
          cancan_action = %w(destroy)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "MedicalAlert"
      case myaction.to_s
        when "crud"
          cancan_action = %w(manage)
        else
          cancan_action = [myaction.to_s]
      end
    elsif controller_name.eql? "Communication"
      case myaction.to_s
        when "view"
          cancan_action = %w(index show)
        else
          cancan_action = [myaction.to_s]
      end
    elsif ['Recall','RecallType'].include?(controller_name)
      case myaction.to_s
        when 'add'
          cancan_action = %w(index  create)
        when 'addpnt'
          cancan_action = %w(index new create)
        when 'edit' , 'editpnt'
          cancan_action = %w(edit update show)
        when 'delete' , 'deletepnt'
          cancan_action = %w(destroy)
        when 'markpnt'
          cancan_action = %w(set_recall_set_date)
      end
    end

    return cancan_action

  end

end
