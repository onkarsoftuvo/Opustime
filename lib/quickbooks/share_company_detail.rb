module Quickbooks
  class ShareCompanyDetail
    attr_accessor :company

    def initialize(company=nil)
      @company = company
    end

  end
end