module PatientTransferExppFilterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filters(params)
      results = self.where(nil)
      filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end
    def filtering_params(params)
      params.slice(
            :patient_id,
            :cnic,
            :transfer_type,
            :confirmation_date_from,
            :confirmation_date_to,
            :transfer_date_from,
            :transfer_date_to,
            :to_province_id,
            :to_district_id
            )
    end
  end
end
