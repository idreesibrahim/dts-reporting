module LabPatientFilterable
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
      params.slice(:cnic, :p_name, :prov_diagnosis, :p_id, :lab_id, :d_from, :d_to, :transfer_status, :district_id, :tehsil_id, :uc_id)
    end
  end
end