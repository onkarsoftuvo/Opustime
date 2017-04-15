task :set_blank_addition_tab_with_value => :environment do
  LetterTemplate.all.each do |letter_temp|
    if letter_temp.addition_tabs.nil?
      letter_temp.update_attributes(addition_tabs: {"practitioner"=>false, "business"=>false, "contact"=>false})  
    end
    Rails.logger.info "#{letter_temp.template_name} done !"
  end
end