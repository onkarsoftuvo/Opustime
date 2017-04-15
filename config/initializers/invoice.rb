InvoiceNumber::Builder.class_eval do
  def initialize(options = {})
    @prefix = options[:prefix] || ''
    @placeholder = options[:placeholder] || '000000000'
  end

  def create(last_number = nil)
    if last_number.present?
      new_number = inc_invoice_number(last_number)
      if new_number.present?
        return "#{@prefix}#{placeholder[(new_number.to_s.size)..(placeholder.size)]}#{new_number}"
      end
    else
      return "#{@prefix}000000001"
    end
  end

  private

  def inc_invoice_number(last_number)
    last_number.to_i + 1
  end
end


