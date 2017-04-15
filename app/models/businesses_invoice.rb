class BusinessesInvoice < ActiveRecord::Base
  belongs_to :business
  belongs_to :invoice
end
