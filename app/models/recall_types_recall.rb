class RecallTypesRecall < ActiveRecord::Base
  belongs_to :recall_type
  belongs_to :recall
end
