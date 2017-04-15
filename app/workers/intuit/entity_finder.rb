module Intuit
  module EntityFinder

    def search(object_classifier, object)
      # check object on qbo by id
      remote_qbo_id1 = object_classifier.fetch_by_id(object.qbo_id)
      # check patient on QBO by name
      remote_qbo_id2 = object_classifier.fetch_by_name(object)

      if remote_qbo_id1.present? && remote_qbo_id2.present? && remote_qbo_id1.to_s.eql?(remote_qbo_id2.to_s)
        return remote_qbo_id1
      elsif remote_qbo_id2.present?
        return remote_qbo_id2
      else
        return nil
      end
    end

  end
end