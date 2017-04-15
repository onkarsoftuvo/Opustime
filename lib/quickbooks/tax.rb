module Quickbooks
  class Tax < Quickbooks::Connection

    # Set QBO tax model attributes
    def set_qbo_attributes_hash(tax_code_name, tax_rate_name, rate_val)
      {
          :TaxCode => "#{tax_code_name}",
          :TaxRateDetails => [
              {
                  :TaxRateName => "#{tax_rate_name}",
                  :RateValue => "#{rate_val}",
                  :TaxAgencyId => '1',
                  :TaxApplicableOn => 'Sales'
              }
          ]
      }
    end


    # Fetch qbo single tax remote object
    def fetch_by_id(qbo_id)
      begin
        @qbo_api.get(:tax_code, qbo_id)
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    def save_company_taxes(qbo_info)
      response = []
      # Quickbooks all tax rates and tax codes
      company_taxes = qbo_info.company.tax_settings.where(:qbo_tax => true).first

      all_tax_codes = fetch_all_tax_code_from_qbo if company_taxes.blank?
      all_tax_rates = fetch_all_tax_rate_from_qbo if company_taxes.blank?
      if all_tax_codes.present? && all_tax_rates.present?

        # get default tax rate
        default_zero_tax_rate = find_default_tax(all_tax_codes, all_tax_rates)
        qbo_info.update_column('tax_code_ref', default_zero_tax_rate)

        all_tax_codes.each do |tax_code|
          sales_taxes = tax_code['SalesTaxRateList']['TaxRateDetail']
          tax_setting_object = qbo_info.company.tax_settings.build(:name => tax_code['Name'], :tax_code_data => tax_code, :tax_code_ref => tax_code['Id'], :qbo_tax => true)
          tax_setting_object.save(:validate => false)
          total_combined_tax = 0
          sales_taxes.each do |sale_tax|
            records = all_tax_rates.select { |tax_rate| tax_rate['Id'].to_i == sale_tax['TaxRateRef']['value'].to_i }
            total_combined_tax += records[0]['RateValue'].to_f
          end
          tax_setting_object.update_column('amount', total_combined_tax)
        end
      end

      # making tax rate response for login company
      company_taxes = TaxSetting.where(:company_id => qbo_info.company.id, :qbo_tax => true)
      company_taxes.all.each do |tax_object|
        tax_object = tax_object.as_json.select { |k, v| ['name','amount','tax_code_ref'].include?(k)}
        tax_object.clone.each do |key,val|
          tax_object['Id'] = val if key.to_s.eql?('tax_code_ref')
        end
        response.push(tax_object.select { |k, v| ['name','amount','Id'].include?(k)})
      end
      # return tax rate response
      response
    end

    # Fetch qbo all tax rate remote object
    def fetch_all_tax_rate_from_qbo
      begin
        result = @qbo_api.query("select * From TaxRate") rescue nil
        return result.present? ? result['QueryResponse']['TaxRate'] : result
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end


    # Fetch qbo all tax code remote object
    def fetch_all_tax_code_from_qbo
      begin
        result = @qbo_api.query('select * From TaxCode') rescue nil
        response = filter_by_Ids(result['QueryResponse']['TaxCode']) if result.present? && result['QueryResponse']['TaxCode'].present?
        return response
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Create tax_code object on QBO
    def create_on_qbo(tax_code_name, tax_rate_name, rate_val)
      begin
        @qbo_api.create(:tax_service, payload: JSON.parse(set_qbo_attributes_hash(tax_code_name, tax_rate_name, rate_val).to_json))
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Remove non integer id's from response
    def filter_by_Ids(response)
      result = []
      response.each { |record| result.push(record) if record['Id'].to_i > 0 }
      result
    end

    # return default Quickbooks zero tax rate tax_code_ref
    def find_default_tax(tax_codes, tax_rates)
      default_zero_tax_rate_ref = tax_rates.select { |record| record['RateValue'].to_i == 0 }

      if default_zero_tax_rate_ref.present?
        default_zero_tax_rate_ref = default_zero_tax_rate_ref[0]['Id']
        tax_codes.each do |tax_code|
          tax_code['SalesTaxRateList']['TaxRateDetail'].each { |s| return tax_code['Id'] if s['TaxRateRef']['value'].to_i == default_zero_tax_rate_ref.to_i }
          tax_code['PurchaseTaxRateList']['TaxRateDetail'].each { |s| return tax_code['Id'] if s['TaxRateRef']['value'].to_i == default_zero_tax_rate_ref.to_i }
        end
      else
        return nil
      end

    end

  end
end