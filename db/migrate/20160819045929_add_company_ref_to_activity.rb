class AddCompanyRefToActivity < ActiveRecord::Migration
  def change
  	add_column :activities , :company_id , :integer
  	add_column :activities , :company_type , :string
  end
end
