class AddbusinessidasreferTopractiavails < ActiveRecord::Migration
  def change
    add_reference :practi_avails , :business, index: true
  end
end
