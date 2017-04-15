class PostController < ApplicationController
	respond_to :json
    before_filter :authorize 
    before_action :find_company_by_sub_domain
    before_action :find_post , :only => [:show , :edit , :update , :destroy]

    # using only for postman to test API. Remove later  
	skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

    
    def index
    	@posts = @company.posts.active_post.order("created_at desc")
    	result = []
    	@posts.each do |pt| 	
    		item = {}
    		item[:id] =pt.id
    		item[:title] =pt.title
    		item[:content] =pt.content
    		item[:posted_at] = pt.created_at.strftime("%d %b %Y")
    		item[:posted_by] = pt.try(:user).try(:full_name)
    		item[:comments] = []
    		comments = pt.comments.active_comment
    		comments.each do |comment|
    			c_item = {}
    			c_item[:comment_id] = comment.id
    			c_item[:body] = comment.body
    			c_item[:created_by] = comment.try(:user).try(:full_name)
    			item[:comments] << c_item
    		end
    		result << item 
    	end
    	render :json => result

    end

    def new
    end

    def create
    	result = {}
    	pst = current_user.posts.new(post_params)
    	if pst.valid?
    		pst.save
    		result = {flag: true , :id => pst.id }
    		render :json => result 
    	else
    		show_error_json(pst.errors.messages)
    	end
    end

    def show
    	result = {}
		result[:id] = @post.id
		result[:title] = @post.title
		result[:content] = @post.content
		result[:comments] = []
		render :json => result
    end

    def edit
    	result = {}
		result[:id] = @post.id
		result[:title] = @post.title
		result[:content] = @post.content
		result[:comments] = []
		render :json => result

    end

    def update
    	result = {}
    	@post.update_attributes(post_params)
    	if @post.valid?
    		@post.save
    		result = {flag: true , :id => @post.id }
    		render :json => result 
    	else
    		show_error_json(@post.errors.messages)
    	end
    end

    def destroy
    	result = {}
    	@post.update_attributes(:status => false )
    	if @post.valid?
    		@post.save
    		result = {flag: true , :id => @post.id }
    		render :json => result 
    	else
    		show_error_json(@post.errors.messages)
    	end
    end

    private

    def post_params
    	params.require(:post).permit(:id , :title , :content , :_destroy)
    end

    def find_post
    	@post = @company.posts.active_post.find_by_id(params[:id])
    end
end
