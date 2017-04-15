class TemplateNotesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :new  , :create ,:import_template_by_file]
  before_action :which_template , :only =>[:show , :edit , :update , :destroy, :download , :import_template_by_file ]

  load_and_authorize_resource  param_method: :template_note_params
  before_filter :load_permissions
  
   def index 
    template_notes = @company.template_notes
    result = []
    
    template_notes.each do| note |
      option_list = ""
      record_temp  = {}
      record_temp[:id] = note.id
      record_temp[:name] = note.name
      record_temp[:no_quest] = note.questions.count
      record_temp[:no_section] = note.temp_sections.count

#     To add option list on hover of the note item   
      option_list = "Address ," if note.show_patient_addr
      option_list += "DOB ," if note.show_patient_dob
      option_list += "Medicare ," if note.show_patient_medicare
      option_list += "Occupation" if note.show_patient_occup  
      
      record_temp[:option_list] = option_list.chomp(",")
      result << record_temp  
    end
    
    render :json=> result  
   end
   
   def new 
     template_note = @company.template_notes.new
     
   end
   
   def create
     # begin
       template_note = @company.template_notes.new(template_note_params)
       if template_note.valid?
        template_note.save
        result = {flag: true , template_id: template_note.id}
        render :json=> result
       else 
        show_error_json(template_note.errors.messages)    
       end   
     # rescue Exception => e
      # render :json=> {error: e.message}        
     # end
   end
   
   def show
    begin
      result = template_format(@template_note)
      render :json=> result  
    rescue
      render :json=> {:error=> "Record not found"}
    end 
     
   end
   
   def edit 
    begin
      unless params[:q]=="clone"
        result = template_format(@template_note)        
      else
        result = template_format(@template_note , true)
      end

      render :json=> result 
    rescue
      render :json=> {:error=> "Record not found"}
    end 
         
   end
   
   def update
#      Adding destroy key in params 
     adding_destroy_key_to_params(params)
     
     @template_note.update_attributes(template_note_params)
     if @template_note.valid?
       @template_note.save
       result = {flag: true , template_id: @template_note.id}
       render :json=> result
     else 
       show_error_json(@template_note.errors.messages)    
     end
     
   end
   
   def destroy
     @template_note.destroy
     render :json=> true
   end
   
#    TO export current template data in json file   
    def download
      begin
        file  = File.open("public/event.json","w")
        @data = template_format(@template_note , true)
        if file
          file.syswrite(@data.to_json)
          send_file file
        end
      rescue Exception => e
        render :nothing=> true 
      end
   end
   
#    Create template from json file 
   def import_template_by_file
     begin
       content = JSON.parse(File.read(params[:file].tempfile))
       template_note = @company.template_notes.new(content)
       if template_note.valid?
         template_note.save
         result = {flag: true , id: template_note.id}
       else
         result = {flag: false} 
       end
       render :json=> result 
     rescue Exception => e
      temp = TemplateNote.new
      temp.errors.add(:imported , "The file was not a Opustime Treatment Note and could not be imported it should be .json(Export)")
      show_error_json(temp.errors.messages)
     end
   end
    
   
   private


   def which_template
     @template_note = TemplateNote.find(params[:id]) rescue nil
   end 
   
   def template_note_params
    params.require(:template_note).permit(:id, :name , :title , :show_patient_addr , :show_patient_dob , :show_patient_medicare , :show_patient_occup ,:_destroy , temp_sections_attributes:[:id, :name , :_destroy , questions_attributes: [:id ,:title , :q_type , :_destroy, quest_choices_attributes: [:id , :title , :_destroy ]]])
    # params.require(:template_note).permit!
   end
   
#    Adjusting destroy key to params 
   def adding_destroy_key_to_params(params)
     section_ids_params = []
     section_ids_params_actual = @template_note.temp_sections.map(&:id)
     section_ids_params = []
     params[:template_note][:temp_sections_attributes].each do |param_temp_section|
      section_ids_params << param_temp_section["id"] unless param_temp_section["id"].nil?        
     end unless params[:template_note][:temp_sections_attributes].nil?
     deletable_section = section_ids_params_actual.compact - section_ids_params.compact
     @template_note.temp_sections.each do |note_section|
      section_quest_ids = note_section.questions.map(&:id)
      params[:template_note][:temp_sections_attributes].each do |param_temp_section|
        if param_temp_section["id"].to_i == note_section.id
          params_section_quest_ids = []
          param_temp_section[:questions_attributes].each do |params_quest|
            qst_choices_ids = []
            unless params_quest["id"].nil?
              params_section_quest_ids << params_quest["id"] 
              quest = Question.find(params_quest["id"])
              qst_choices_ids = quest.quest_choices.map(&:id)
            end
            params_qst_choices_ids = []
            params_quest[:quest_choices_attributes].each do |quest_ch|
              params_qst_choices_ids << quest_ch["id"]  unless quest_ch["id"].nil? 
            end unless params_quest[:quest_choices_attributes].nil?
            
            deletable_choices =  qst_choices_ids.compact - params_qst_choices_ids.compact
            params_quest[:quest_choices_attributes] = [] if params_quest[:quest_choices_attributes].nil?
            deletable_choices.each do |choice_id|
              params_quest[:quest_choices_attributes] << {:id=> choice_id , :_destroy=> true}  
            end
             
          end unless param_temp_section[:questions_attributes].nil?
          
          deletable_question = section_quest_ids.compact - params_section_quest_ids.compact
          param_temp_section[:questions_attributes] = []  if param_temp_section[:questions_attributes].nil?
          deletable_question.each do |q_id|
            param_temp_section[:questions_attributes] << {:id=> q_id , :_destroy=> true}  
          end
        end        
      end unless params[:template_note][:temp_sections_attributes].nil?
     end
     params[:template_note][:temp_sections_attributes] = []  if params[:template_note][:temp_sections_attributes].nil?
     deletable_section.each do |section_id |
      params[:template_note][:temp_sections_attributes] <<  {:id=> section_id , :_destroy=> true} 
     end
   end
   
   #  To show the specific attributes of template and its associations      

   def template_format(template_note , download_format=false)
      result = {}
      result[:id] = template_note.id unless download_format 
      result[:name] = template_note.name
      result[:temp_sections_attributes] = []
      sections  = template_note.temp_sections
      sections.each do |section|
        set_section = {}
        set_section[:id] = section.id unless download_format 
        set_section[:name] = section.name
        set_section[:questions_attributes] = []
        section.questions.each do |qs|
          set_qs = {}
          set_qs[:id] = qs.id unless download_format 
          set_qs[:title] = qs.title
          set_qs[:q_type] = qs.q_type
          set_qs[:quest_choices_attributes] = []
          qs.quest_choices.each do |choice|
            set_choice = {}
            set_choice[:id] = choice.id unless download_format 
            set_choice[:title] = choice.title
            set_qs[:quest_choices_attributes] << set_choice 
          end 
          set_section[:questions_attributes] << set_qs
        end
        result[:temp_sections_attributes] << set_section
      end
      result[:show_patient_addr] = template_note.show_patient_addr
      result[:show_patient_dob] = template_note.show_patient_dob
      result[:show_patient_medicare] = template_note.show_patient_medicare
      result[:show_patient_occup] = template_note.show_patient_occup
      
      return result 
   end
   
end
