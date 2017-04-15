class AddQboIdIntoModels < ActiveRecord::Migration
  def change
    change_table :patients do |t|
      t.integer :qbo_id,:limit=>8
    end
    change_table :products do |t|
      t.integer :qbo_id,:limit=>8
      t.integer :income_account_ref
      t.integer :expense_account_ref
    end

    change_table :billable_items do |t|
      t.integer :qbo_id,:limit=>8
      t.integer :income_account_ref
      t.integer :expense_account_ref
    end

    change_table :invoices do |t|
      t.integer :qbo_id,:limit=>8
    end

    change_table :payments do |t|
      t.integer :qbo_id,:limit=>8
    end

    change_table :expenses do |t|
      t.integer :qbo_id,:limit=>8
      t.integer :income_account_ref
      t.integer :expense_account_ref
    end

    change_table :expense_vendors do |t|
      t.integer :qbo_id,:limit=>8
    end

  end
end
