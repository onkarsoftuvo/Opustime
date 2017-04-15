class ChangeColumnTypAvailabilityToWaitList < ActiveRecord::Migration
  def change
    change_column :wait_lists , :availability , :string
  end
end
