require 'sidekiq/web'

Rails.application.routes.draw do


  constraints(Subdomain) do
    get "/subdomain" => "authentication#get_subdomain"
    post "sign_in" => "authentication#login", :defaults => { :format => 'json' }
    get "signed_out" => "authentication#signed_out"
    get "getsession" => "authentication#get_session" , :defaults => { :format => 'json' }

    resources :letter_templates

    resources :referral_types
    match "/referrals" => "referral_types#referral" , :via => [:get]

    match "/invoice_settings" => "invoice_settings#edit" , :via=> [:get]
    match "/invoice_settings/:id" => "invoice_settings#update" , :via=> [:put , :patch]

    match "/document_and_printings" => "document_and_printings#edit" , :via=> [:get]
    match "/document_and_printings/:id" => "document_and_printings#update" , :via=> [:put , :patch]
    match "/document_and_printings/:id/upload" => "document_and_printings#logo_upload" , :via=> [:put , :patch]


    match "/appointment_reminders" => "appointment_reminders#edit" , :via=> [:get]
    match "/appointment_reminders/:id" => "appointment_reminders#update" , :via=> [:put , :patch]


    scope "/settings"  do

      get "account" => "accounts#edit"
      put "account/:id" => "accounts#update"
      put "account/:id/upload" => "accounts#logo_upload"
      get "account/attendee" => "accounts#get_attendee"

      get "online_booking" => "online_booking#edit"
      put "online_booking/:id" => "online_booking#update"
      put "online_booking/:id/upload" => "online_booking#upload"
      get "user/appointment_types" => "users#get_appointment_type_list"
      get '/permission_matrix' => 'users#permission_matrix'

      get "appointment_type/products" => "appointment_type#products_list"
      get "appointment_type/billable_items" => "appointment_type#billable_items_list"
      get "letter_template/tabs_info" => "letter_templates#get_all_tabs_info"
      get "doctors" => "users#all_practitioners"

      post "integrations/mail_chimp" => "integrations#mail_chimp_integration"
      get "integrations/mail_chimp/info" => "integrations#get_mail_chimp_info"
      put "integrations/fb/page_id" => "integrations#save_fb_page_id"
      delete "integrations/fb_page_remove" => "integrations#remove_fb_page_id"
      get "facebook/pages" => "integrations#facebook_pages_list"

      get "xero_sessions/new"  => "xero_sessions#new"
      get "xero_sessions/connect_info"  => "xero_sessions#is_xero_connected"
      get "xero_sessions/disconnect"  => "xero_sessions#disconnect"
      put "xero_sessions/save_info"  => "xero_sessions#save_xero_settings"
      get "tax/xero_info" => "tax_settings#xero_info_for_tax"
      get "payment_type/xero_info" => "payment_types#xero_info_for_payment_type"
      get "billable_item/xero_info" => "billable_items#xero_info_for_billable_items"

      # For QuickBook API
      get "/quickbook/accounts_list" => "quick_book#index"
      get "/quickbook/authenticate" => "quick_book#authenticate"
      get "/quickbook/oauth_callback" => "quick_book#oauth_callback"
      get '/quickbook/status'=>'quick_book#qbo_status'
      get '/quickbook/disconnect'=>'quick_book#disconnect_qbo'
      get '/quickbook/tax_and_accounts_list'=>'quick_book#tax_and_accounts_list'
      get '/quickbook/expense_accounts'=>'quick_book#expense_accounts_list'
      post '/quickbook/save_account_setting'=>'quick_book#save_account_setting'
      get '/quickbook/sync_taxes'=>'quick_book#sync_qbo_taxes'


      # for Authorize.net
      get '/authorizenet/card_registration_status'=>'credit_card#card_status'
      get '/authorizenet/sms_credit_payment'=>'credit_card#sms_credit'
      post '/authorizenet/card_registration'=>'credit_card#add_vault'
      put '/authorizenet/card_updation'=>'credit_card#update_vault'

      # for 2 factor Authentication
      post '/user/google_authenticator'=>'user_mfa_session#create'
      get '/user/google_authenticator/resend_qr_code'=>'user_mfa_session#resend_qr_code'
      put '/users/:id/upload' => 'users#logo_upload'
      get '/users/:id/ical' => 'users#generate_ical_event'

      resources :business
      resources :users do
        collection do
          get '/security_roles' => 'users#check_security_role'
        end
        get '/sms_items' => 'users#sms_items', :on => :member
      end

      resources :appointment_type


      resources :concession_type
      resources :billable_items
      resources :tax_settings
      resources :payment_types
      resources :recall_types do
        collection do
          get '/security_roles' => 'recall_types#check_security_role'
        end
      end
      resources :template_notes  do
        get 'download', on: :member
      end
      resources :exports , :only => [:index , :create , :show , :destroy ] do
        get 'download', on: :member
        collection do
          get "/lists" => "exports#lists"
          get "/check_access_permission_export" => "exports#check_access_permission_export"
          get "/tr_notes" => "exports#get_treatment_notes"
        end
      end
      resources :imports , :only => [:index , :create , :show , :update, :destroy] do
        member do
          get "/records" => "imports#records"
          get "/records/back" => "imports#records"
        end
        collection do
          get "/list/attributes" => "imports#get_model_names"
        end

      end

      resources :sms_templates do
        collection do
          get "list" => "sms_templates#list"
        end
        member do
          get "drop_downs_items" => "sms_templates#get_drop_down_listing_items"
        end
      end


      post "import/template" => "template_notes#import_template_by_file"
      get "billableitemslist" => "billable_items#billable_item_list"
      match "/sms_setting/edit" => "sms_setting#edit" , :via=>[:get]
      match "/sms_setting" =>"sms_setting#update" , :via=>[:put]
      match "/subscription" =>"subscription#index" , :via=>[:get]
      match "/subscription" =>"subscription#update" , :via=>[:put]
      post '/subscription/cancel'=>'subscription#cancel'
      get '/subscription/auto_credit'=>'subscription#wallet_balance'
      get '/subscription/state'=>'subscription#permission'
    end

    resources :appointments  , :shallow=> true do
      member do
        get '/future/booking' => 'appointments#future_appnt_print' , :defaults => { :format => 'pdf' }
        get "/booking" => "appointments#appointment_show_online_booking"
        get "/logs" => "appointments#view_logs"
        get "/booking/print" => "appointments#appointment_show_online_booking_pdf"
        put "/booking/partial/update" => "appointments#update_partially_booking"
        get "/patient/arrival" => "appointments#patient_arrival"
        put "partial/update" => "appointments#update_partially"
        get "/template_notes" => "appointments#get_template_notes"
      end
      collection do
        get '/security_roles' => 'appointments#check_security_role'
        post "/booking" => "appointments#create_appnt_through_online_booking"
        get "/:business_id/practitioners/availabilities" => "appointments#practitioners_availability"
        get "/:business_id/practitioners" => "appointments#location_wise_available_doctors"
        get "/:b_id/practitioners/:id/:appointment_type/availability" => "appointments#check_practitioner_availability_for_specific_day_and_time_on_a_location"
        get "/:business_id/time-specific" => "appointments#get_appointments_in_time_period"
        get "/:business_id/:doctor_id/availability/extra" => "availabilities#index"
        post "/:business_id/:doctor_id/availability" => "availabilities#create"
        get "/vailability/:id/" => "availabilities#show"
        get "/availability/:id/edit" => "availabilities#edit"
        put "/:business_id/:doctor_id/availability/:id" => "availabilities#update"
        put "/:doctor_id/availability/:id/partial" => "availabilities#update_partially"
        delete "/availability/:id" => "availabilities#destroy"
        get  "/:practitioner_id/appointment_types" => "appointments#practitioner_wise_appointment_types"
        get "/calendar/settings" => "appointments#calendar_setting"
        get "/:patient_id/treatment_notes/details" => "appointments#treatment_notes"
      end
    end

    match "/xero/complete" => "xero_sessions#recieve_xero_token" , :via=> :get
    match "/booking" => "bookings#booking_show_page" , :via=> [:get , :post]
    match "/booking/info" => "bookings#online_booking_info" , :via=> :get
    match "/booking/locations" => "bookings#avail_business_locations" , :via=> :get
    match "/booking/color_option" => "bookings#avail_color_option" , :via=> :get
    match "/booking/patient_country_info" => "bookings#get_business_info" , :via=> :get
    match "/booking/:business_id/services" => "bookings#available_services" , :via=> :get
    match "/booking/:business_id/services/:service_id/practitioners" => "bookings#service_wise_practitioners" , :via=> :get
    match "/booking/:b_id/practitioners/:id/:appointment_type/availability" => "bookings#practitioner_availability_for_a_month" , :via=> :get
    match "/booking/specific_date/:b_id/practitioners/:id/:appointment_type/availability" => "bookings#practitioner_availability_on_specific_date" , :via=> :get
    match "/booking/patient_detail_by_cookie" => "bookings#get_patient_detail_by_token" , :via=> :post
    match "/booking/appointments/:id/ical/generate" => "bookings#generate_ical_event" , :via=> [:get]
    match "/booking/appointments/:id/patient/send_email" => "bookings#email_to_others" , :via=> [:post]
    match "/auth/google_oauth2/callback" => "bookings#verify_calendar_auth" , :via=> :get
    match "/auth/facebook/callback" => "bookings#facebook_login" , :via=> :get
    match "/facebook/current_path" => "bookings#save_path" , :via=> :get
    match "/facebook/get_data" => "bookings#get_data" , :via=> :get
    match "/facebook/remove_data" => "bookings#remove_fb_detail" , :via=> :get
    match "/appointments/:id/google/calendar" => "bookings#google_calendar" , :via=> :get

    resources :wait_lists  , :shallow=> true do
      collection do
        get ":business_id/practitioner/:doctor_id" => "wait_lists#wait_lists_as_per_appointment_type"
      end
    end

    resources :products , only: [:index, :create, :update, :edit  , :destroy] do
      resources :product_stocks , only: [:index , :create]
      collection do
        get "/security_roles" => "products#check_security_role"
      end
    end


    resources :expenses do
      collection do
        get "/categories" => "expenses#categories_list_from_model"
        get "/vendors" => "expenses#vendors_list_from_model"
        get "/security_roles" => "expenses#check_security_role"
      end
    end
    resources :contacts , only: [:index , :new , :create , :show , :edit , :update , :destroy] do
      member do
        post "/send_sms" => "contacts#send_sms"
        get "/sms_item" => "contacts#sms_items"
      end
      collection do
        get "/security_roles" => "contacts#check_security_role"
      end

    end

    scope "/expense"  do
      get "list/vendors" => "expenses#vendors_list"
      get "list/categories" => "expenses#category_list"
      get "list/products" => "expenses#product_list"
    end

    resources :communications , only: [:index , :show]
    match "communications/check/security_roles" => "communications#check_security_role" , :via=> [:get]
    match "/communications/:id/print" => "communications#communication_print" , :via=> [:get]

    resources :patients do
      put 'upload' => 'patients#upload'
      resources :medical_alerts , :shallow=> true
      collection do
        get "/doctors" => "patients#doctors_list"
        get "/related_patients" => "patients#list_related_patients"
        get "/contacts" => "patients#list_contact"
        get "/get/authority" => "patients#user_role_wise_authority"
      end
      member do
        get "has_wait_list" => "patients#has_patient_wait_list"
        put "/delete_permanent" => "patients#permanent_delete"
        put "/active" => "patients#status_active"
        post "/account_statement" => "patients#account_statement"
        get "/account_statement/print" => "patients#account_statement_pdf"
        post "/merge" => "patients#patient_merge"
        get "/identical" => "patients#identical"
        get "/account_history" => "patients#account_history"
        get "/client_profile" => "patients#clients_modules"
        get "/send_email" => "patients#send_email"
        post "/send_sms" => "patients#send_sms"
        get "/sms_item" => "patients#sms_items"
        get "/submodules" => "patients#get_patient_submodules_total"
      end

      resources :appointments , :only=> [:index]

      resources :treatment_notes , :shallow=> true do
        collection do
          get "/template_notes" => "treatment_notes#get_template_notes"
          get "/get_previous_treatment_note" => "treatment_notes#get_previous_treatment_note"
          get "/appointments" => "treatment_notes#patient_appointments_list"

        end
        member do
          get "/generate_pdf" => "treatment_notes#export_tr_note_to_pdf"
        end
      end
      resources :recalls , :shallow=> true do
        member do
          get "/set_recall_date" => "recalls#set_recall_set_date"
        end
      end
      resources :letters , :shallow=> true do
        collection do
          get "/letter_templates" => "letters#letter_templates"
        end
      end
      member do
        post "/files/upload" => "file_attachments#upload"
      end
      resources :file_attachments , :only=>[:update ,:destroy , :edit , :show , :view_name] , :shallow=> true

    end

    match "/letter/send_email" => "letters#send_letter_via_email" , :via=> [:post]
    match "/letters/:id/info" => "letters#get_data_for_send_email" , :via=> [:get]
    match "/letters/:id/print" => "letters#letter_print" , :via=> [:get]
    match "/letter_templates/:id/letter_detail" => "letters#get_letter_template_detail" , :via=> [:get]
    match "/recall_types/:id/recall_format" => "recalls#get_recall_type_details" , :via=> [:get]
    match "patients/:patient_id/template_notes/:id/previous_treatment_note" => "treatment_notes#get_previous_treatment_note" , :via=> [:get]
    match "/template_notes/:id/template_format" => "treatment_notes#get_template_note_details" , :via=> [:get]

    resources :invoices do
      resources :invoice_items , shallow: true
      collection do
        get "/security_roles" => "invoices#check_security_role"
      end
    end

    match "/payments/:id/print" => "payments#payment_print" , :via=> [:get]
    match "invoice/:invoice_id/payments/new" => "payments#new" ,:via=>[:get]
    get "patient/:id/:payment_id/invoices" => "payments#patient_outstanding_invoices"
    get "payment/payment_types" => "payments#avail_payment_types"
    get "payments/search" => "payments#search"
    # post "patient/:patient_id/payments" => "payments#create"

    # resources :payments , :except=> [:create]
    resources :payments do
      collection do
        get "/security_roles" => "payments#check_security_role"
      end
    end
    match "/invoices/:id/send_email" => "invoices#send_email_with_pdf" , :via=> [:get]
    match "/invoices/:id/print" => "invoices#invoice_print" , :via=> [:get]
    match "/practitioners" =>"invoices#list_doctors" , :via=>[:get]
    match "/list/patients" =>"invoices#patients_list" , :via=>[:get]
    match "/list/products" =>"invoices#products_list" , :via=>[:get]
    match "/list/appointment_types" =>"invoices#appointment_types_list" , :via=>[:get]
    match "/invoice/appointment_types/:patient_id/:id" =>"invoices#get_invoice_item_appointmentwise" , :via=>[:get]
    match "/list/businesses" =>"invoices#business_list" , :via=>[:get]
    match "patient/:patient_id/billable_items" =>"invoices#billable_item_list" , :via=>[:get]

    match "/appointments/:id/:practitioner_id" =>"invoices#patient_detail" , :via=>[:get]
    # match "/:patient_id/billable_items/:id" =>"invoices#billable_item_details" , :via=>[:get]
    # match "/product/:id/product_detail" =>"invoices#product_details" , :via=>[:get]

    resources :sms_center , :only => [:index] do
      collection do
        post "/get_data" => "sms_center#get_data"
        get "/filters" => "sms_center#filters"
        get "/patients/get_numbers" => "sms_center#get_objects_with_phone_nos"
        post "/send_sms" => "sms_center#send_sms"
        get "/logs" => "sms_center#get_logs"
        get "/downloads/logs" => "sms_center#download_logs" , :defaults => { :format => 'csv' }
        post "/receive_sms" => "sms_center#sms_receive"
        get "/numbers" => "sms_center#get_numbers"
        post "/buy_number" => "sms_center#buy_number"
        get '/custom' =>  'sms_center#chat_history_of_unknown_no'
      end
    end

    # generate reports
    resources :reports , :only => [:index] do
      collection do
        get "/appointments" => "reports#show_appointments_list"
        get "/appointments/list" => "reports#only_list_data"
        get "/appointments/export" => "reports#export" , :defaults => { :format => 'csv' }
        get "/appointments/generate_pdf" => "reports#generate_pdf" , :defaults => { :format => 'pdf' }
      end
    end

    resources :practitioner_reports , :only => [:index] do
      collection do
        get "list" => "practitioner_reports#list_info"
        get "export" => "practitioner_reports#export" , :defaults => { :format => 'csv' }
        get "/generate_pdf" => "practitioner_reports#generate_pdf" , :defaults => { :format => 'pdf' }
      end
    end

    resources :patient_reports , :only => [:index] do
      collection do
        get "/list" => "patient_reports#patient_listing"
        get "/recall/list" => "patient_reports#recall_patients"
        get "/recall/list/export" => "patient_reports#recall_patients_export" , :defaults => { :format => 'csv' }
        get "/recall/list/pdf" => "patient_reports#recall_patients_pdf" , :defaults => { :format => 'pdf' }

        get "/birthday_export" => "patient_reports#birthday_list_export" , :defaults => { :format => 'csv' }
        get "/birthday_pdf" => "patient_reports#birthday_list_pdf" , :defaults => { :format => 'pdf' }

        get "/patients_list_export" => "patient_reports#patient_list_export"
        get "/patients_list_pdf" => "patient_reports#patient_list_pdf" , :defaults => { :format => 'pdf' }

        get "/list/without_upcoming_appointments" => "patient_reports#patients_without_upcoming_appnt"
        get "/list/upcoming_export" => "patient_reports#patients_without_upcoming_appnt_export"

        get "/list/upcoming_pdf" => "patient_reports#patients_without_upcoming_appnt_pdf" , :defaults => { :format => 'pdf' }
      end
    end

    resources :revenue_reports , :only => [:index] do
      collection do
        get "/list"  => "revenue_reports#revenue_list"
        get "/list/export" => "revenue_reports#revenue_export" , :defaults => { :format => 'csv' }
        get "/list/pdf" => "revenue_reports#revenue_pdf" , :defaults => { :format => 'pdf' }
      end
    end

    resources :daily_reports , :only => [:index] do
      collection do
        get "/locations"  => "daily_reports#locations"
        get "/list/export" => "daily_reports#daily_report_export" , :defaults => { :format => 'csv' }
        get "/list/pdf" => "daily_reports#daily_report_pdf" , :defaults => { :format => 'pdf' }
        get "/chart_data" => "daily_reports#chart_data"
      end
    end

    resources :expense_reports , :only => [:index] do
      collection do
        get "/categories" => "expense_reports#get_categories"
        get "/listing" => "expense_reports#listing"
        get "/listing/export" => "expense_reports#listing_export" , :defaults => { :format => 'csv' }
      end
    end

    resources :referral_type_patients , :only => [:index] do
      collection do
        get "/chart_data"  => "referral_type_patients#chart_data"
        get "/export" => "referral_type_patients#export" , :defaults => { :format => 'csv' }
        get "/generate_pdf" => "referral_type_patients#generate_pdf" , :defaults => { :format => 'pdf' }
      end
    end

    match "/dashboard" => "dashboard#index"  , :via => [:get]
    match "/dashboard/locations" => "dashboard#locations"  , :via => [:get]
    match "/dashboard/appnts_reports" => "dashboard#appointments_reports"  , :via => [:get]
    match "/dashboard/sales_chart" => "dashboard#sales_chart" , :via => [:get]
    match "/dashboard/coming_appnt" => "dashboard#coming_appointments" , :via => [:get]
    match "/dashboard/item_sales_chart" => "dashboard#product_sale_chart" , :via => [:get]
    match "/dashboard/activity_logs" => "dashboard#get_activity" , :via => [:get]
    match "/dashboard/admin_permission" => "dashboard#admin_ds_permission" , :via => [:get]
    match "/dashboard/report_options" => "dashboard#report_options" , :via => [:post]
    match "/dashboard/get_report_options" => "dashboard#get_report_options" , :via => [:get]

    resources :post do
      resources :comments
    end


    get '/authorized/modules' => "settings#show_module_role_wise"
    get '/:country/states' => "settings#country_states_courrency"
    get '/dashboard/modules' => "home#dashboard_rolewise_authentication"

    get '/home/get_theme' => 'home#get_theme'

    # push notification controller
    resources :notifications,:only=>[:index] do
      get '/open'=>'notifications#marked_open',:on=>:collection
    end

    get 'auth/facebook', as: 'auth_provider'

    # timezone controller routes
    get '/timezones'=>'timezone#show'
    get '/csv_import' => "enateimport#csv_import"
    get "enateimport" => "enateimport#import"
    get "/deleteimport" => "enateimport#deleteimport"
    get '/improve_import' => "enateimport#improve_import"
    get '/improve_enate' => "enateimport#improve_enate"

    get '/users/update_language' => 'users#update_language'
  
end


  match "/booking" => "bookings#booking_show_page" , :via=> [:get , :post]

  #added by manoranjan
  get 'cities/:state', to: 'application#cities'

  scope module: 'admin' do

    get "admin_panel/view" => "admin#view"
    get 'admin/signup'=>'admin#sign_up'
    post 'admin/users'=>'admin#create_user'
    get "list/business_list" => "business_report#business_list"
    get "list/business_customer" => "business_report#business_customer"
    get "earn/business_earning" => "business_report#business_earning"
    get "earn/business_location" => "business_report#business_location"
    get "earn/business_financial" => "business_report#business_financial"
    get "business/:id/details" => "business_report#business_detail"
    get "business/:id/details_list" => "business_report#business_detail_list"
    get "business/:id/demo" => "business_report#demo"
    get "business/:id/edit_user" => "business_report#edit_user"
    get 'business/:id/clear_attempt' => 'business_report#clear_attempts'
    get "business/:id/edit_business" => "business_report#edit_business"
    get "business/:id/edit_patient" => "business_report#edit_patient"
    post '/business/sms_credit_popup' => 'business_report#sms_credit_popup'
    post '/business/:id/sms_credit' => 'business_report#sms_credit' , as: :business_sms_credit
    get "list/financial_list" => "financial_report#financial_bus_list"
    get "earn/financial_earn" => "financial_report#financial_bus_earn"
    get "list/trial_user" => "trial_user#trial_user"
    post 'list/trial_user/extend_trail'=>'trial_user#extend_trial'
    # get "notification/business" => "admin_notification#business_notification"
    # get "notification/user" => "admin_notification#user_notification"
    # get "notification/email" => "admin_notification#email_notification"
    #get "package/sub" => "admin_subscription#sub_package"
    #get "package/add_sub" => "admin_subscription#add_sub_package"
    #get "subscription/:id/add" => "admin_subscription#add_package"
    get "sms/package" => "admin_sms#sms_package"
    get "sms/consumption" => "admin_sms#sms_consumption"
    get "sms/number" => "admin_sms#sms_number"
    get "others/request" => "admin_other#import_delete_request"
    delete '/import/:id/delete' => 'admin_other#import_destroy'
    get "others/business_subscription" => "admin_other#business_subscription"
    get "others/business_payments" => "admin_other#business_payments"
    get "business/:id/subscription_history" => "admin_other#subscription_history",:as=>'subscription_history'
    get "business/:id/payment_history" => "admin_other#payment_history",:as=>'payment_history'
    get "sms_setting/:id/sms_credit" => "admin_sms_setting#sms_credit"
    get "sms_setting/sms_edit" => "admin_sms_setting#sms_edit"
    resources :admin_subscription
    resources :admin_sms
    resources :admin_sms_setting
    resources :admin_sms_setting
    resources :admin_sms_groups
    resources :sms_number
  end

  namespace :admin do
    resources :admin_companies,:admin_business,:admin_patients, :only => [:new , :edit, :update]
    resource :admin_profiles, :only => [:new , :edit,:update]
    match "owners/:id/upload" => "admin_profiles#upload", via: :patch
    get "permission" => "permission#admin_permission"
    get "permission/logs" => "permission#admin_logs"
    post "permission/dashboard" => "permission#dashboard"
    post "permission/save" => "permission#create"
    post "permission/patient_save" => "permission#patient_create"
    post "permission/invoice_save" => "permission#invoice_create"
    post "permission/payment_save" => "permission#payment_create"
    post "permission/product_save" => "permission#product_create"
    post "permission/expense_save" => "permission#expense_create"
    post "permission/contact_save" => "permission#contact_create"
    post "permission/pntfile_save" => "permission#pntfile_create"
    post "permission/announcemsg_save" => "permission#announcemsg_create"
    post "permission/userinfo_save" => "permission#userinfo_create"
    post "permission/communication_save" => "permission#communication_create"
    post "permission/medical_save" => "permission#medical_create"
    post "permission/treatnote_save" => "permission#treatnote_create"
    post "permission/letter_save" => "permission#letter_create"
    post "permission/recall_save" => "permission#recall_create"
    post "permission/report_save" => "permission#report_create"
    post "permission/dataexport_save" => "permission#dataexport_create"
    post 'permission/setting_save' => 'permission#setting_create'

    get "sign_in" => "admin#sign_in"
    get "sign_out" => "admin#sign_out"
    post "login" => "admin#login"

    resources :approvals,:only=>[:index,:destroy] do
      member do
        get 'active_inactive', :action => 'active_or_inactive'
      end
    end


    # logs table action routes
    get 'logs/opustime_logs' => 'logs#system_logs'
    get 'opustime_logs/company_list' => 'logs#companies_list'
    get 'opustime_logs/company_user_list' => 'logs#company_user_list'
    post 'opustime_logs/company_logs' => 'logs#company_logs'
    post 'opustime/quickbooks_logs'=>'logs#quickbooks_logs'
    post 'opustime/authorizenet_logs'=>'logs#transaction_logs'
    post 'opustime/admin_logs'=>'logs#administration_logs'

    # admin users permission
    resources :user_permission , :only=> [:index] do
      collection do
        post 'apply' => 'user_permission#apply_permission'
      end
    end

  end


  mount Delayed::Web::Engine, at: '/jobs'
  devise_for :owners, controllers: { sessions: 'admin/owners/sessions',registrations: 'admin/owners/registrations' }


  namespace :admin do
    resource :dashboards,:only=>[:none] do
      get :home
    end
  end

  get '/get_login_email' => 'authentication#get_login_email'
  get '/home_page' => 'authentication#home_page'
  post "sign_in" => "authentication#login", :defaults => { :format => 'json' }
  get "sign_in" => "authentication#sign_in"
  get "check_account" => "authentication#check_account_existance"
  get "search_account" => "authentication#search_account"
  get "search_company" => "authentication#search_company"
  get 'home/index'

  resources :registers
  resources :password_resets
  get "/subdomain" => "authentication#get_subdomain"


  root 'home#index'
  mount Sidekiq::Web, at: "/sidekiq"

  get '/\*path' => redirect('/?goto=%{path}')
  match '*path' => redirect('/'), via: :get

end
