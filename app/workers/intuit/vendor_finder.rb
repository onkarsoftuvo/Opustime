module Intuit
  module VendorFinder

    def search(vendor_classifier, vendor, business_name)
      # check patient on QBO by name
      remote_qbo_id, qbo_business_name = vendor_classifier.fetch_by_name(vendor)
      if remote_qbo_id.present? && remote_qbo_id.to_s.eql?(vendor.qbo_id) && qbo_business_name.to_s.eql?(business_name)
        return vendor.qbo_id
      elsif remote_qbo_id.present?
        return remote_qbo_id
      else
        return nil
      end
    end

  end

end