class CommentsController < ApplicationController
	respond_to :json
    before_filter :authorize 
    before_action :find_company_by_sub_domain
    before_action :find_comment , :only => [:destroy]
    before_action :find_post , :only => [:create]

    # using only for postman to test API. Remove later  
	skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

    def create
    	result = {}
    	@comment = @post.comments.new(comment_params)
    	if @comment.valid?
    		@comment.save
    		result = {flag: true , :id => @comment.id }
    		render :json => result 
    	else
    		show_error_json(@comment.errors.messages)
    	end
    	
    end

    def destroy
    	result = {}
    	@comment.update_attributes(status: false)
    	if @comment.valid?
    		@comment.save
    		result = {flag: true , :id => @comment.id }
    		render :json => result
    	else
    		show_error_json(@comment.errors.messages)
    	end
    end

    private 

    def comment_params
    	params.require(:comment).permit(:id , :_destroy , :body ).tap do |whitelisted|
    		whitelisted[:user_id] = current_user.id
    	end
    end

    def find_post
    	@post = @company.posts.find_by_id(params[:post_id])
    end

    def find_comment
    	@comment = Comment.find_by_id(params[:id])
    end

end
