class Concession < ActiveRecord::Base
  belongs_to :company
  
  # has_many :billable_items , :through=> :company
  # has_and_belongs_to_many :billable_items , :dependent=> :destroy
  
  has_many :concessions_patients , :dependent=> :destroy
  has_many :concessions, :through => :concessions_patients, :dependent => :destroy
  
  has_many :billable_items_concessions , :dependent=> :destroy
  has_many :billable_items , :through=> :billable_items_concessions ,  :dependent=> :destroy
  # accepts_nested_attributes_for :billable_items_concessions , :allow_destroy => true
  
#   later validations 
  # validates_associated :company
  # validates :name , presence: true , uniqueness: { case_sensitive: false }
  validates :name , presence: true 
  
#   ending here ----  
  
  # after_create :add_concession_in_billableitems
  # after_update :update_concession_in_billableitems
  # before_destroy :delete_concession_in_billableitems
  
  # def add_concession_in_billableitems
    # company = self.company
    # company.billable_items.each do |item|
# #     To create common record for both
      # item_wise_concession = BillableItemsConcession.new( billable_item_id: item.id , concession_id: self.id , value: 0 ,name: self.name)
#       
# #       To insert values of all concessions into all billable items
      # if item_wise_concession.valid?
        # item_wise_concession.save
        # item.concession_price = []
        # BillableItemsConcession.where(["billable_item_id =?", item.id]).select("concession_id as id, name , value").each do |item_cs|
          # add_cs_item = {id: item_cs.id , name: item_cs.name , value: (item_cs.value.to_i == 0 ? "":item_cs.value)}
          # item.concession_price << add_cs_item   
        # end
        # item.save   
      # end
#       
# 
    # end
#     
  # end
#   
  # def update_concession_in_billableitems
    # company = self.company
    # BillableItemsConcession.where(["concession_id =?", self.id]).select("id, name,value").each do |item_cs|
      # item_cs.update_attributes(:name=> self.name , :value=> item_cs.value.to_i)
    # end
    # serialize_billablecs_data(company)
#     
  # end
#   
  # def delete_concession_in_billableitems
    # company = self.company
    # BillableItemsConcession.where(["concession_id =?", self.id]).select("id, name").each do |item_cs|
      # item_cs.destroy
    # end
    # serialize_billablecs_data(company)
#     
  # end
#   
  # private 
#   
  # def serialize_billablecs_data(company)
    # company.billable_items.each do |item|
      # item.concession_price = []
      # BillableItemsConcession.where(["billable_item_id =?", item.id]).select("concession_id as id, name , value").each do |item_cs|
        # item.concession_price << {id: item_cs.id , name: item_cs.name , value: (item_cs.value.to_i == 0 ? "":item_cs.value)}  
      # end
      # item.save
    # end
  # end 
  
end

