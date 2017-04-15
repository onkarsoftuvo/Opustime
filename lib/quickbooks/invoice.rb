module Quickbooks
  class Invoice < Quickbooks::Connection
    include Intuit::EntityFinder
    # Set QBO Invoice model attributes
    def set_qbo_attributes_hash(invoice, token, secret, realm_id, qbo_credential)
      invoice_items = invoice.invoice_items
      all_invoice_items = []

      if invoice_items.size > 0
        invoice_items.each do |line_item|
          item = line_item.item_type.to_s.eql?('Product') ? Product.find_by_id(line_item.item_id) : BillableItem.find_by_id(line_item.item_id)
          qbo_item = Quickbooks::Item.new(token, secret, realm_id)
          # searching Item or Service on QBO
          search_object_id = search(qbo_item, item)
          # create item on Quickbooks if item reference not present in db
          search_object_id.present? ? qbo_item.update_on_qbo(search_object_id,item, qbo_credential) : qbo_item.create_on_qbo(item, qbo_credential)

          if qbo_credential.tax_code_ref.present?

            if item.tax_setting.present?

              all_invoice_items.push({
                                         :Amount => line_item.quantity*line_item.unit_price,
                                         :DetailType => 'SalesItemLineDetail',
                                         :SalesItemLineDetail => {
                                             :ItemRef => {
                                                 :value => "#{item.qbo_id}",
                                                 :name => "#{item.name}"
                                             },
                                             :Qty => "#{line_item.quantity}",
                                             :UnitPrice => "#{line_item.unit_price}",
                                             :TaxCodeRef => {
                                                 # :value => item.tax_setting.present? ? 'TAX' : 'NON'
                                                 :value => "#{item.tax_setting.tax_code_ref}"
                                             }
                                         }
                                     })
            else
              all_invoice_items.push({
                                         :Amount => line_item.quantity*line_item.unit_price,
                                         :DetailType => 'SalesItemLineDetail',
                                         :SalesItemLineDetail => {
                                             :ItemRef => {
                                                 :value => "#{item.qbo_id}",
                                                 :name => "#{item.name}"
                                             },
                                             :Qty => "#{line_item.quantity}",
                                             :UnitPrice => "#{line_item.unit_price}",
                                             :TaxCodeRef => {
                                                 :value => "#{qbo_credential.tax_code_ref}"
                                             }
                                         }
                                     })

            end
          else

            all_invoice_items.push({
                                       :Amount => line_item.quantity*line_item.unit_price,
                                       :DetailType => 'SalesItemLineDetail',
                                       :SalesItemLineDetail => {
                                           :ItemRef => {
                                               :value => "#{item.qbo_id}",
                                               :name => "#{item.name}"
                                           },
                                           :Qty => "#{line_item.quantity}",
                                           :UnitPrice => "#{line_item.unit_price}"

                                       }
                                   })

          end

        end
      end

      # include discount line in an invoice
      if invoice.total_discount > 0
        all_invoice_items.push({
                                   :DetailType => 'DiscountLineDetail',
                                   :DiscountLineDetail => {
                                       :PercentBased => true,
                                       :DiscountPercent => total_discount(invoice),
                                   }
                               })
      end

      {
          :DocNumber => "#{invoice.id}",
          :TxnDate => "#{invoice.issue_date}",
          :Line => all_invoice_items,
          :GlobalTaxCalculation => qbo_credential.tax_code_ref.present? ? 'TaxExcluded' : 'NotApplicable',
          # :TxnTaxDetail => {
          #     :TxnTaxCodeRef => {
          #         :value => "#{tax_code_val.try(:tax_code_ref)}"
          #     }
          # },
          :CustomerRef => {
              :value => "#{invoice.patient.qbo_id}"
          }
      }

    end


    # Fetch qbo remote object
    def fetch_by_id(qbo_id)
      begin
        @qbo_api.get(:invoice, qbo_id)['Id'] rescue nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Create Invoice object on QBO
    def create_on_qbo(invoice, token, secret, realm_id, qbo_credential)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(qbo_credential.company)
        response = @qbo_api.create(:invoice, payload: JSON.parse(set_qbo_attributes_hash(invoice, token, secret, realm_id, qbo_credential).to_json))
        invoice.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(invoice, 'Successfully created on QBO', 'create', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(invoice, error.message, 'create', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(invoice, error.message, 'create', true, logs)
      end

    end

    # Update Invoice object on QBO
    def update_on_qbo(qbo_id, invoice, token, secret, realm_id, qbo_credential)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(qbo_credential.company)
        response = @qbo_api.update(:invoice, id: qbo_id, payload: JSON.parse(set_qbo_attributes_hash(invoice, token, secret, realm_id, qbo_credential).to_json))
        invoice.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(invoice, 'Successfully updated on QBO', 'update', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(invoice, error.message, 'update', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(invoice, error.message, 'update', true, logs)
      end

    end

    # Delete Invoice object on QBO
    def delete_on_qbo(qbo_id, invoice)
      begin
        logs = Quickbooks::Logs.new(invoice.patient.company)
        response = @qbo_api.delete(:invoice, id: qbo_id)
        if response['status'].to_s.eql?('Deleted')
          logs.update_success_log(invoice, 'Successfully deleted on QBO', 'delete', false, logs)
        else
          logs.update_success_log(invoice, 'Not deleted on QBO', 'delete', false, logs)
        end
      rescue Faraday::ConnectionFailed
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(invoice, error.message, 'delete', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(invoice, error.message, 'delete', true, logs)
      end
    end

    # calculate total discount on an invoice
    def total_discount(invoice)
      return (((invoice.total_discount*100).to_f)/(invoice.total_discount+invoice.subtotal)).round(3)
    end

    # def item_price_including_tax
    #
    # end

    # check is an item is tax inclusive or exclusive
    def is_inclusive_or_exclusive(item)
      if item.class.to_s.eql?('Product')
        Product.is_tax_included?(item) ? (return 'inclusive') : (return 'exclusive')
      else
        item.include_tax ? (return 'inclusive') : (return 'exclusive')
      end
    end

    def qbo_global_tax_setting(invoice)
      count = 0
      invoice_items = invoice.invoice_items
      invoice_items.each do |invoice_item|
        item = invoice_item.item
        if invoice_item.item.class.to_s.eql?('Product')
          count += 1 if Product.is_tax_included?(item)
        else
          count += 1 if item.include_tax
        end
      end
      return (count > 0) ? 'TaxInclusive' : 'TaxExcluded'
    end

    def unit_amount_include_tax(item)
      tax_amount = (item.total_price.to_f - (item.unit_price.to_f * item.quantity))/item.quantity.to_f
      return item.unit_price.to_f + tax_amount
    end

  end
end