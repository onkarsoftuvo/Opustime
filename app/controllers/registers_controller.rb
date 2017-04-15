class RegistersController < ApplicationController
  include ApplicationHelper

  respond_to :json
  skip_before_filter :verify_authenticity_token, :only => [:create, :update]

  def create
    comp = Company.new(params[:company])
    remote_ip_address = request.remote_ip
    if comp.valid?
      comp.save
      # Ip address geo-coding to get country and timezone
      query = Geocoder.search(remote_ip_address)
      country = query.first.data['country_name'] rescue nil
      time_zone = query.first.data['time_zone'] rescue nil
      # unless request.base_url.include?('www')
      #   splitted_path = request.base_url.split('//')
      #   login_path = splitted_path[0] + '//' + comp.company_name.to_s.downcase + '.' + splitted_path[1] + "/#!/signup/#{comp.id}"
      # else
      #   login_path = request.base_url.gsub('www', "www.#{@company.company_name.to_s.downcase}") + "/#!/signup/#{comp.id}"
      # end
      login_path = get_redirect_path(comp , "/#!/signup/#{comp.id}")
      render :json => {:comp_id => comp.id, :country_name => country, :time_zone => time_zone, :cycle => "1" , next_path: login_path }
    else
      show_error_json(comp.errors.messages)
    end
  end

  def update
    comp = Company.find(params[:company][:id])
    if (params[:company].keys.include? "first_name") && (params[:company].keys.include? "last_name")

      comp.update_attributes(params[:company].except("id"))
      if comp.valid? && params[:company][:terms] == true
        user = comp.users.last
        log_in user
        render :json => {flag: true, session_id: session[:user_id], :user_name => session[:user_name]}
      else
        comp.errors.add(:terms_and_conditions , 'must be accepted ')  if  params[:company][:terms] == false || params[:company][:terms].nil?
        show_error_json(comp.errors.messages)
      end
    else
      comp.errors.add(:first_name, "can't be left blank")
      comp.errors.add(:last_name, "can't be left blank")
      show_error_json(comp.errors.messages)
    end
  end

  private

  def get_redirect_path(company , sub_path)
    coming_path = request.base_url.sub(/^www\./, '')
    coming_path = coming_path.gsub(request.subdomain , company.company_name.to_s.downcase.gsub(' ','-')) unless request.subdomain.blank?
    requested_path = URI.parse(request.base_url).host
    splitted_path = coming_path.split('//')
    if requested_path.split('.').length <= 2
      login_path = splitted_path[0] + '//' + company.company_name.to_s.downcase.gsub(' ','-') + '.' + splitted_path[1] + sub_path
    else
      login_path = splitted_path[0] + '//' + splitted_path[1] + sub_path
    end

  end

end
