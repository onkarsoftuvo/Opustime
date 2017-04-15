module Admin::AdminOtherHelper
	def owner
    	Owner.find(session[:owner_id]).first_name + " " + Owner.find(session[:owner_id]).last_name
	end

end
