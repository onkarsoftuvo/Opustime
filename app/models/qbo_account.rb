require 'rake'
Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
Enake::Application.load_tasks # providing your application name is 'sample'

class QboAccount < ActiveRecord::Base

  scope :account_details, ->(account_ref) { where(account_ref: account_ref) }
   belongs_to :company
  # def self.run_rake
  #   Rake::Task['quickbooks:update_income_and_expense_accounts'].reenable
  #   Rake::Task['quickbooks:update_income_and_expense_accounts'].invoke
  # end

end
