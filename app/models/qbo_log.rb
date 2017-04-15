class QboLog < ActiveRecord::Base
  belongs_to :company
  belongs_to :loggable,:polymorphic => true
end
