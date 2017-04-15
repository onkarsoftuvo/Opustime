class LetterTemplatesLetter < ActiveRecord::Base
  belongs_to :letter
  belongs_to :letter_template
end
