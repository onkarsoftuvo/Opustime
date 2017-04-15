class Communication < ActiveRecord::Base
  belongs_to :patient
  
  self.per_page = 30
  validates :message , presence:true
  def next_communication
    comp = self.patient.company
    comm_ids = []
    comm_ids = comp.communications.order("communications.created_at desc").ids unless comp.nil?
    ele_index = comm_ids.index(self.id)
    next_elem = comm_ids.at(ele_index + 1)
    return next_elem
  end
  
  def prev_communication
    comp = self.patient.company
    comm_ids = []
    comm_ids = comp.communications.order("communications.created_at desc").ids unless comp.nil?
    ele_index = comm_ids.index(self.id)
    prev = ele_index - 1
    prev_elem = (prev<0 ? nil : comm_ids.at(prev))
    return prev_elem
  end
  
end
