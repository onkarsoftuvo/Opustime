class DocumentAndPrintingsController < ApplicationController
 respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:edit]
  before_action :find_document_and_printing , :only => [:update , :logo_upload]

  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  # load_and_authorize_resource  param_method: :document_and_printing_params
  # before_filter :load_permissions

	def edit
    (authorize! :edit , DocumentAndPrinting)
     document_and_printing = @company.document_and_printing
     main_result = {}
     
     result = {}
     result[:id] = document_and_printing.id
     result[:logo_height] = document_and_printing.logo_height
     result[:in_page_size] = document_and_printing.in_page_size
     result[:have_logo] = (document_and_printing.logo.to_s.include?"missing.png") ? false : true
     result[:in_top_margin] = document_and_printing.in_top_margin
     result[:show_invoice_logo] = document_and_printing.show_invoice_logo
     result[:as_title] = document_and_printing.as_title
     result[:l_space_un_logo] = document_and_printing.l_space_un_logo
     result[:l_top_margin] = document_and_printing.l_top_margin
     result[:l_bottom_margin] = document_and_printing.l_bottom_margin
     result[:l_bleft_margin] = document_and_printing.l_bleft_margin
     result[:l_right_margin] = document_and_printing.l_right_margin
     
     result[:tn_page_size] = document_and_printing.tn_page_size
     result[:tn_top_margin] = document_and_printing.tn_top_margin
     result[:l_display_logo] = document_and_printing.l_display_logo
     
     result[:tn_display_logo] = document_and_printing.tn_display_logo
     result[:hide_us_cb] = document_and_printing.hide_us_cb
     
     result[:logo] = document_and_printing.logo
     main_result["document_and_printing"] = result
     render json: main_result 
	
	end

	def update
    (authorize! :update , DocumentAndPrinting)
	  document_and_printing = @document_and_printing.first
    document_and_printing.update(document_and_printing_params)
    if document_and_printing.valid?
      result = {flag: true }
      render json: result  
    else 
      show_error_json(document_and_printing.errors.messages)
    end
	end
	
	def logo_upload
    (authorize! :update , DocumentAndPrinting)
	  document_and_printing = @document_and_printing.first
	  document_and_printing.update_attributes(:logo=> params[:file])
    if document_and_printing.valid?
      result = {flag: true }
      render json: result  
    else 
      show_error_json(document_and_printing.errors.messages)
    end
	end

  private

  def document_and_printing_params
    params.require(:document_and_printing).permit(:id, :logo_height , :in_page_size , :in_top_margin ,:show_invoice_logo ,:as_title , :l_space_un_logo, :l_top_margin, :l_bottom_margin, :l_bleft_margin, :l_right_margin, :tn_page_size , :tn_top_margin, :l_display_logo, :tn_display_logo,:hide_us_cb , :status).tap do |whitelisted|
      whitelisted[:logo] = nil if params[:document_and_printing][:remove_logo]      
    end
  end

  def find_document_and_printing
    @document_and_printing = DocumentAndPrinting.where(id: params[:id])
  end

end
