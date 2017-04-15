class OccurrenceAvail < ActiveRecord::Base
  belongs_to :availability
  belongs_to :childavailability , :class_name=> "Availability"
end
