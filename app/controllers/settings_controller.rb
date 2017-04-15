class SettingsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:edit , :update , :show_module_role_wise]
  
  
  def show_module_role_wise
    available_modules = {}
  end
  
  def country_states_courrency
    result = {}
    country = ISO3166::Country.new(params[:country])
    unless country.nil?
      state_keys = country.states.keys
      states = []
      state_keys.each do |key|
        item = {}
        item[:state_code] =  key
        item[:name] = country.states[key]["name"]
        states << item 
      end
      result[:country_name] = country.name
      result[:states] = states
      result[:currency_symbol] = country.currency['symbol']
    end
    render :json => result 
  end


  
end
