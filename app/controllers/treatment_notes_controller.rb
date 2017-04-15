class TreatmentNotesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :create , :new, :get_template_notes , :get_template_note_details , :export_tr_note_to_pdf ]
  before_action :find_note , :only => [:show , :edit , :update , :destroy , :export_tr_note_to_pdf]
  before_action :find_patient , :only => [:index,:create , :get_previous_treatment_note  , :patient_appointments_list]
  before_filter :set_current_user , :only => [ :create , :edit , :update , :destroy]
  before_action :set_appointment_into_params , :only => [:create , :update]

  # using only for postman to test API. Remove later
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  
  def index 
    treatment_notes = @patient.treatment_notes.active_treatment_note
    result = []
    treatment_notes.each do |note|
      item = {}
      item[:id] = note.id
      item[:template_id] = note.template_id 
      item[:appointment_id] = note.appointment.try(:id) 
      item[:treatment_sections_attributes] = []
      sections  = note.treatment_sections
      sections.each do |section|
        set_section = {}
        set_section[:id] = section.id
        set_section[:name] = section.name
        set_section[:treatment_questions_attributes] = []
        section.treatment_questions.each do |qs|
          set_qs = {}
          set_qs[:id] = qs.id
          set_qs[:title] = qs.title
          set_qs[:quest_type] = qs.quest_type
          set_qs[:treatment_quest_choices_attributes] = []
          qs.treatment_quest_choices.each do |choice|
            set_choice = {}
            set_choice[:id] = choice.id
            set_choice[:title] = choice.title
            set_choice[:treatment_answer_attributes] = {}
            quest_answer = choice.treatment_answer
            treatment_answer_item = {}
            treatment_answer_item[:id] = quest_answer.id
            treatment_answer_item[:is_selected] = quest_answer.is_selected unless ["Text","Paragraph"].include?qs.quest_type
            treatment_answer_item[:ans] = quest_answer.ans if ["Text","Paragraph"].include?qs.quest_type
            set_choice[:treatment_answer_attributes] = treatment_answer_item
            set_qs[:treatment_quest_choices_attributes] << set_choice 
          end 
          set_section[:treatment_questions_attributes] << set_qs
        end
        item[:treatment_sections_attributes] << set_section
      end    
      item[:save_final] = note.save_final
      item[:created] = note.created_at.strftime("%d %b %Y")
      item[:last_updated] = note.updated_at.strftime("%d %b %Y") == note.created_at.strftime("%d %b %Y") ? nil : note.updated_at.strftime("%d %b %Y") 
      result << item
    end
    render :json=> result   
  end
  
  def new
    result = {}
    result[:id] = nil
    result[:template_id] = nil
    result[:appointment_id] = nil
    result[:treatment_notes_template_note_attributes] = {:template_id=> nil}
    result[:treatment_sections_attributes] = []
    treatment_sections_item = {}
    treatment_sections_item[:id] =  nil
    treatment_sections_item[:name] =  nil
    treatment_sections_item[:treatment_questions_attributes] =  []
    treatment_questions_item = {}
    treatment_questions_item[:id] = nil
    treatment_questions_item[:title] = nil
    treatment_questions_item[:quest_type] = nil
    treatment_questions_item[:treatment_quest_choices_attributes] = []
    treatment_quest_choices_item = {}
    treatment_quest_choices_item[:id] = nil
    treatment_quest_choices_item[:title] = nil
    treatment_quest_choices_item[:treatment_answer_attributes] = {}
    treatment_answer_item = {}
    treatment_answer_item[:id] = nil
    treatment_answer_item[:is_selected] = nil
    treatment_answer_item[:ans] = nil
    
    treatment_quest_choices_item[:treatment_answer_attributes] = treatment_answer_item
    treatment_questions_item[:treatment_quest_choices_attributes] << treatment_quest_choices_item
    treatment_sections_item[:treatment_questions_attributes] << treatment_questions_item
    result[:treatment_sections_attributes] << treatment_sections_item
    render :json=> {treatment_note: result}
      
  end
  
  def create
    unless (can? :view_all , TreatmentNote) || (can? :view_own , TreatmentNote)
      authorize! :view_own , TreatmentNote
    end

    set_ans_for_multi_choice_question(params) unless params[:treatment_note].length == 0
    unless @patient.nil?
      treatment_note = @patient.treatment_notes.new(treatment_note_params)
      if treatment_note.valid?
        treatment_note.save
        result = {flag: true , id: treatment_note.id }
        render :json => result
      else
        show_error_json(treatment_note.errors.messages)
      end 
    else
      treatment_note = TreatmentNote.new
      treatment_note.errors.add(:patient , "Not found !")
      treatment_note.valid?
      show_error_json(treatment_note.errors.messages)
    end 
  end
  
  def edit
    authorize! :edit_own , TreatmentNote
    result = {}
    # result = get_treatment_note_format(@treatment_note)
    result[:id] = @treatment_note.id
    result[:treatment_notes_template_note_attributes] = {:template_note_id => @treatment_note.template_note.id , template_note_name: @treatment_note.template_note.name}
    result[:title] =  @treatment_note.title
     
    result[:appointment_id] = @treatment_note.appointment.try(:id) 
    result[:treatment_sections_attributes] = []
    sections  = @treatment_note.treatment_sections
    sections.each do |section|
      set_section = {}
      set_section[:id] = section.id
      set_section[:name] = section.name
      set_section[:treatment_questions_attributes] = []
      section.treatment_questions.each do |qs|
        set_qs = {}
        set_qs[:id] = qs.id
        set_qs[:title] = qs.title
        set_qs[:quest_type] = qs.quest_type
        ans_data = nil
        ans_data = qs.treatment_answers.map(&:ans).uniq.compact.first if (params[:action] == "edit" && qs.quest_type.casecmp("Multiple_Choice")==0)
        set_qs[:ans] = (params[:action] == "get_template_note_details" ? nil : ans_data) if qs.quest_type.casecmp("Multiple_Choice")==0
        set_qs[:treatment_quest_choices_attributes] = []
        qs.treatment_quest_choices.each do |choice|
          set_choice = {}
          set_choice[:id] = choice.id
          set_choice[:title] = choice.title
          set_choice[:treatment_answer_attributes] = {}
            quest_answer = choice.treatment_answer
            treatment_answer_item = {}
            treatment_answer_item[:id] = quest_answer.id
            treatment_answer_item[:is_selected] = quest_answer.is_selected unless ["Text","Paragraph"].include?qs.quest_type
            treatment_answer_item[:ans] = quest_answer.ans if ["Text","Paragraph"].include?qs.quest_type
          set_choice[:treatment_answer_attributes] = treatment_answer_item
          set_qs[:treatment_quest_choices_attributes] << set_choice 
        end 
        set_section[:treatment_questions_attributes] << set_qs
      end
      result[:treatment_sections_attributes] << set_section
    end    
    result[:save_final] = @treatment_note.save_final
    session[:patient_id] = @treatment_note.patient.id
    render :json=> {treatment_note: result} 
    
  end
  
  def update
    authorize! :edit_own , TreatmentNote
    if @treatment_note.template_note.id == params[:treatment_note][:treatment_notes_template_note_attributes][:template_note_id].to_i
      set_ans_for_multi_choice_question(params) unless params[:treatment_note].length == 0
      @treatment_note.update_attributes(treatment_note_params)
      if @treatment_note.valid?
        result = {flag: true , id: @treatment_note.id }
        render :json => result
      else
        show_error_json(@treatment_note.errors.messages)
      end            
    else
      @treatment_note.update_attributes(:status=> false)
      set_ans_for_multi_choice_question(params) unless params[:treatment_note].length == 0
      @patient = Patient.find(session[:patient_id]) rescue nil 
      unless @patient.nil?
        treatment_note = @patient.treatment_notes.new(treatment_note_params)
        if treatment_note.valid?
          treatment_note.save
          result = {flag: true , id: treatment_note.id }
          render :json => result
        else
          show_error_json(treatment_note.errors.messages)
        end 
      else
        treatment_note = TreatmentNote.new
        treatment_note.errors.add(:patient , "Not found !")
        treatment_note.valid?
        show_error_json(treatment_note.errors.messages)
      end
    end
    session.delete :patient_id
  end
  
  def destroy
    authorize! :delete , TreatmentNote
    @treatment_note.update_attributes(:status=> false)
    if @treatment_note.valid?
      result = {flag: true , id: @treatment_note.id }
      render :json => result
    else
      show_error_json(@treatment_note.errors.messages)
    end
  end
  
  def patient_appointments_list
    appointments = @patient.appointments.active_appointment.select("id , appnt_date , appnt_time_start , appnt_time_end ")
    result = []
    appointments.each do |appnt|
      item = {}
      item[:id]  = appnt.id
      appnt_date_m = appnt.appnt_date.strftime("%d %b %Y")
      appnt_time_m = appnt.appnt_time_start.strftime("%H:%M%p")
      full_name = appnt_date_m + ", " + appnt_time_m + " - " + appnt.appointment_type.try(:name)
      item[:name] = full_name
      result << item 
    end
    render :json=> {patient_appointments: result }
  end 
    
  def get_previous_treatment_note
   result = {} 
   last_treatment_note =  @patient.treatment_notes.active_treatment_note.joins(:treatment_notes_template_note).where(["treatment_notes_template_notes.template_note_id=?" , params[:id]]).order("treatment_notes.created_at desc").first 
   unless last_treatment_note.nil?
     result = get_treatment_note_format(last_treatment_note)
   else
     template_note = TemplateNote.find(params[:id]) rescue nil
     result = get_template_format(template_note ,false)      
   end 
   render :json=> {:treatment_note=> result }
  end
  
  def get_template_notes
    template_notes = @company.template_notes.select("id , name")
    render :json => template_notes 
  end
  
  def get_template_note_details
    result = {}
    template_note = @company.template_notes.find(params[:id]) rescue nil
    unless template_note.nil?
      result = get_template_format(template_note ,false)
    end 
    render :json=> {treatment_note: result }
  end
  
  def export_tr_note_to_pdf
    unless (can? :view_all , TreatmentNote) || (can? :view_own , TreatmentNote)
      authorize! :view_own , TreatmentNote
    end
#   Getting setting info for print from setting/document and printing
    print_setting = @company.document_and_printing
    @logo_url = print_setting.logo

#   setting missing image if logo is not available  
    if (@logo_url.to_s.include?"/assets/") 
      @logo_url = @logo_url.to_s.split("/assets/")[1]
    end

    @logo_size = print_setting.logo_height
    page_size = print_setting.tn_page_size
    top_margin = print_setting.tn_top_margin
    @show_invoice_logo = print_setting.tn_display_logo
    hide_unselected_checkbox = print_setting.hide_us_cb 
    @result = get_treatment_note_detail_for_pdf(@treatment_note , hide_unselected_checkbox)
    # render :json=> @result 
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => "pdf_name.pdf" , 
               :layout => '/layouts/pdf.html.erb' ,
               :disposition => 'inline' ,
               :template    => "/treatment_notes/export_tr_note_to_pdf.pdf.erb",
               :show_as_html => params[:debug].present? ,
               :footer=> { right: '[page] of [topage]' },
               :margin =>  { top:  top_margin.to_i },
               :page_size  => page_size 
      end
    end
    
    
  end
   
  def set_current_user
    TreatmentNote.current = current_user
  end
  
  
  private
  
  def treatment_note_params
    params.require(:treatment_note).permit(:id , :title  , :save_final , :treatment_notes_template_note_attributes => [:id , :template_note_id, :_destroy],
    :treatment_notes_appointment_attributes => [:id , :appointment_id ,:_destroy] , 
     :treatment_sections_attributes=>[:id, :name,:_destroy,
       :treatment_questions_attributes=>[:id , :title , :quest_type,:ans , :_destroy ,
         :treatment_quest_choices_attributes=>[:id , :title, :_destroy ,
           :treatment_answer_attributes=>[:id , :is_selected , :ans, :_destroy]
     ]] ]).tap do |whitelisted|
       whitelisted[:title] = set_treatment_title(whitelisted[:treatment_notes_template_note_attributes]) unless whitelisted[:treatment_notes_template_note_attributes].nil?  
     end
  end 
  
  def get_template_format(template_note , download_format=false)
      result = {}
      # result[:template_id] = template_note.id unless download_format
      result[:appointment_id] = nil 
      result[:treatment_sections_attributes] = []
      sections  = template_note.temp_sections
      sections.each do |section|
        set_section = {}
        set_section[:name] = section.name
        set_section[:treatment_questions_attributes] = []
        section.questions.each do |qs|
          set_qs = {}
          set_qs[:q_id] = qs.id.to_s
          set_qs[:title] = qs.title
          set_qs[:quest_type] = qs.q_type
          ans_data = nil
          ans_data = qs.treatment_answers.map(&:ans).uniq.compact.first if (params[:action] == "edit" && qs.q_type.casecmp("Multiple_Choice")==0)
          set_qs[:ans] = (params[:action] == "get_template_note_details" ? nil : ans_data) if qs.q_type.casecmp("Multiple_Choice")==0 
          set_qs[:treatment_quest_choices_attributes] = []
          qs.quest_choices.each do |choice|
            set_choice = {}
            set_choice[:title] = choice.title
            set_choice[:treatment_answer_attributes] = {}
              treatment_answer_item = {}
              treatment_answer_item[:is_selected] = false if qs.q_type.casecmp("Checkboxes") == 0
              if ["Text","Paragraph"].include?qs.q_type
                treatment_answer_item[:ans] = nil
              elsif qs.q_type.casecmp("Multiple_Choice")==0
                treatment_answer_item[:ans] = (params[:action] == "get_template_note_details" ? nil : ans_data)
              end
              # treatment_answer_item[:ans] = nil if ["Text","Paragraph,Multiple_Choice"].include?qs.q_type
            set_choice[:treatment_answer_attributes] = treatment_answer_item
            set_qs[:treatment_quest_choices_attributes] << set_choice 
          end 
          set_section[:treatment_questions_attributes] << set_qs
        end
        result[:treatment_sections_attributes] << set_section
      end
      
      return result 
   end
   
   def find_patient
     @patient = Patient.find(params[:patient_id]) rescue nil
   end
   
   def find_note
     @treatment_note = TreatmentNote.find(params[:id]) rescue nil
   end 
   
   def set_ans_for_multi_choice_question(params)
    params[:treatment_note][:treatment_sections_attributes].each do |tr_section|
      tr_section[:treatment_questions_attributes].each do |tr_quest|
        if tr_quest["quest_type"] == "Multiple_Choice"
          ans_data = tr_quest[:ans]
          tr_quest[:treatment_quest_choices_attributes].each do |tr_q_ch|
            if tr_q_ch[:title] == ans_data
              tr_q_ch[:treatment_answer_attributes][:ans] = ans_data
            else 
              tr_q_ch[:treatment_answer_attributes][:ans] = nil
            end
          end
        end
      end
    end     
   end
   
   def set_appointment_into_params
     unless  params[:treatment_note][:appointment_id].nil?
     # when treatment has already different appnt then remove join table record 
       unless action_name == "create" 
         treatment_note = TreatmentNote.find_by_id(params[:treatment_note][:id]) 
         appointment = treatment_note.appointment
         unless appointment.nil?
           if appointment.id != params[:treatment_note][:appointment_id]
             TreatmentNotesAppointment.where(treatment_note_id: treatment_note.id , appointment_id: appointment.id ).first.destroy
           end 
         end
       end
       
       params[:treatment_note][:treatment_notes_appointment_attributes] = {:appointment_id => params[:treatment_note][:appointment_id] }
     else
       unless params[:treatment_note][:id].nil?
         treatment_note = TreatmentNote.find(params[:treatment_note][:id]) rescue nil
         appointment = treatment_note.appointment
         unless appointment.nil?
          tr_note_appnt = TreatmentNotesAppointment.find_by_treatment_note_id_and_appointment_id(treatment_note.id ,appointment.id )
          params[:treatment_note][:treatment_notes_appointment_attributes] = {:id => tr_note_appnt.id , :_destroy=> true }     
         end
       end
     end 
   end 
   
   def set_treatment_title(treatment_notes_template)
     TemplateNote.find(treatment_notes_template[:template_note_id]).name rescue nil 
   end 
   
   
   
   def get_treatment_note_format(treatment_note)
     result = {}
     result[:id] = treatment_note.id unless (params[:action] <=> "get_previous_treatment_note") == 0
     result[:treatment_notes_template_note_attributes] = {:template_note_id => treatment_note.template_note.id , template_note_name: treatment_note.template_note.name}
     result[:title] =  treatment_note.title
     # result[:appointment_id] = treatment_note.appointment.try(:id)
     result[:treatment_sections_attributes] = []
     sections  = treatment_note.treatment_sections
     sections.each do |section|
       set_section = {}
       set_section[:id] = section.id unless (params[:action] <=> "get_previous_treatment_note") == 0
       set_section[:name] = section.name
       set_section[:treatment_questions_attributes] = []
       section.treatment_questions.each do |qs|
         set_qs = {}
         set_qs[:id] = qs.id unless (params[:action] <=> "get_previous_treatment_note") == 0
         set_qs[:title] = qs.title
         set_qs[:quest_type] = qs.quest_type
          
         ans_data = nil
         ans_data = qs.treatment_answers.map(&:ans).uniq.compact.first if (params[:action] == "edit" && qs.quest_type.casecmp("Multiple_Choice")==0) || (params[:action] == "get_previous_treatment_note" && qs.quest_type.casecmp("Multiple_Choice")==0) 
         set_qs[:ans] = (params[:action] == "get_template_note_details" ? nil : ans_data) if qs.quest_type.casecmp("Multiple_Choice")==0
         set_qs[:treatment_quest_choices_attributes] = []
         qs.treatment_quest_choices.each do |choice|
           set_choice = {}
           set_choice[:id] = choice.id unless (params[:action] <=> "get_previous_treatment_note") == 0
           set_choice[:title] = choice.title
           set_choice[:treatment_answer_attributes] = {}
             quest_answer = choice.treatment_answer
             treatment_answer_item = {}
             treatment_answer_item[:id] = quest_answer.id unless (params[:action] <=> "get_previous_treatment_note") == 0
             treatment_answer_item[:is_selected] = quest_answer.is_selected unless ["Text","Paragraph"].include?qs.quest_type
             treatment_answer_item[:ans] = quest_answer.ans if ["Text","Paragraph"].include?qs.quest_type
           set_choice[:treatment_answer_attributes] = treatment_answer_item
           set_qs[:treatment_quest_choices_attributes] << set_choice 
         end 
         set_section[:treatment_questions_attributes] << set_qs
       end
       result[:treatment_sections_attributes] << set_section
     end    
     result[:save_final] = treatment_note.save_final
     
     return result
   end
   
   def get_treatment_note_detail_for_pdf(note , hide= false )
     item = {}
     patient= note.patient
     patient_info = {}
     patient_info[:name] = patient.full_name
     patient_info[:address] = patient.full_address
     patient_info[:dob] = patient.dob
     patient_info[:occupation] = patient.occupation
     patient_info[:medicare_no] = patient.medicare_number
     
     item[:patient] = patient_info
     item[:id] = note.id
     user =  User.find(note.created_by_id) rescue nil 
     item[:created_by] = user.full_name unless user.nil?
     item[:treatment_title] = note.title 
     item[:appointment_id] = note.appointment.try(:id)
     item[:practitioner_name] =  user.full_name_with_title
     item[:note_created_at]  = note.created_at.strftime("%d %b %Y ,%H:%M %p")
     item[:company_name] = note.template_note.company.company_name
     item[:note_last_updated] = note.updated_at.strftime("%d %b %Y ,%H:%M %p")
     item[:template_default_title] =  note.template_note.title.nil? ? note.template_note.name : note.template_note.title 
     item[:treatment_sections_attributes] = []
     sections  = note.treatment_sections
     sections.each do |section|
       set_section = {}
       set_section[:name] = section.name
       set_section[:treatment_questions_attributes] = []
       section.treatment_questions.each do |qs|
         set_qs = {}
         set_qs[:title] = qs.title
         set_qs[:quest_type] = qs.quest_type
         check_box_ans_data = ""
         check_box_ans_data_2 = []

         qs.treatment_quest_choices.each do |choice|
           quest_answer = choice.treatment_answer
           unless ["Text","Paragraph"].include?qs.quest_type
             unless qs.quest_type =="Multiple_Choice"
               ans_data = {} 
               if hide 
                 if quest_answer.is_selected
                  ans_data[:is_selected] = true
                  ans_data[:ans_option] = choice.title
                  check_box_ans_data_2 << ans_data
                 end 
               else
                ans_data[:is_selected] = quest_answer.is_selected
                ans_data[:ans_option] = choice.title
                check_box_ans_data_2 << ans_data
               end
             end
           else
             check_box_ans_data = quest_answer.ans 
           end
         end
         if qs.quest_type.casecmp("Multiple_Choice")==0
           ans_data = nil
           ans_data = qs.treatment_answers.map(&:ans).uniq.compact.first
           set_qs[:ans] = ans_data 
         else
           if qs.quest_type.casecmp("Checkboxes")==0
             set_qs[:ans] = check_box_ans_data_2 
           else
             set_qs[:ans] = check_box_ans_data
           end
         end
         set_section[:treatment_questions_attributes] << set_qs
       end
       item[:treatment_sections_attributes] << set_section
     end    
     item[:save_final] = note.save_final
     item[:created] = note.created_at.strftime("%d %b %Y")
     item[:last_updated] = note.updated_at.strftime("%d %b %Y") == note.created_at.strftime("%d %b %Y") ? nil : note.updated_at.strftime("%d %b %Y")
     return item 
   end
   
end