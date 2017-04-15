class CommunicationsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index]
  before_action :find_communication , :only => [:show]

  load_and_authorize_resource
  before_filter :load_permissions

  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : Communication.per_page
     unless params[:q].blank? || params[:q].nil?
       q = params[:q]
       arr = q.split(" ")
       if arr.length == 2
         communications = @company.communications.joins(:patient).where([" patients.first_name LIKE ? OR patients.last_name LIKE ? OR patients.first_name LIKE ? OR patients.last_name LIKE ? OR communications.comm_type LIKE ? OR communications.category LIKE ? ", "%#{arr.first}%", "%#{arr.last}%", "%#{arr.last}%", "%#{arr.first}%", "%#{params[:q]}%" , "%#{params[:q]}%" ]).order("communications.created_at desc").select("communications.id , communications.comm_type ,communications.comm_time , communications.category  , communications.direction  , communications.patient_id , communications.send_status , communications.link_id").paginate(:page => params[:page] , :per_page=> per_page)
       else
         communications = @company.communications.order("communications.created_at desc").paginate(:page => params[:page] , :per_page=> per_page)
       end
     else
      communications = @company.communications.order("communications.created_at desc").paginate(:page => params[:page] , :per_page=> per_page)
     end
     result = []
     communications.each do |comm|
       item = {}
       item[:id] = comm.id
       item[:date] = comm.comm_time.strftime("%Y-%m-%d")
       item[:comm_type] = comm.comm_type
       item[:category] = comm.category
       item[:patient] = comm.patient.nil? ? nil : comm.patient.full_name
       item[:direction] = comm.direction
       # item[:to] = comm.to
       # item[:from] = comm.from
       # item[:message] = comm.message
       item[:send_status] = comm.send_status
       # item[:link_item] = comm.link_item
       item[:link_id] = comm.link_id
       item[:practitioner] = ""
       result << item 
     end

    render :json=> {communications: result , total: communications.count }
  end
  
  def show
    result = {}
    result[:id] = @communication.id
    result[:communication_time] = @communication.comm_time
    result[:type] = @communication.comm_type
    result[:category] = @communication.category
    result[:direction] = @communication.direction
    result[:to] = @communication.to
    result[:from] = @communication.from
    result[:message] = @communication.message
    result[:send_status] = @communication.send_status
    result[:link_item] = @communication.link_item
    result[:link_id] = "0"*(6-@communication.link_id.to_s.length)+ @communication.link_id.to_s     
    result[:patient_id] = @communication.patient.id
    result[:next] = @communication.next_communication
    result[:prev] = @communication.prev_communication
    render :json=> result 
  end

  def check_security_role
    result = {}
    result[:view] = can? :index , Communication
    render :json => result
  end
  
  private
  
  def find_communication
    @communication = Communication.find(params[:id])
  end
  
end
