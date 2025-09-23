module PatientFilterable
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
      params.slice(:place, :act_tag, :cnic, :tehsil_id, :patient_name, :district_id, :outcome, :patient_status, :prov_diagnosis, :uc_id, :p_id, :hospital_id, :datefrom, :dateto, :confirm_datefrom, :confirm_dateto, :facility_type, :hospital_category, :condition, :confirm_by, :tehsil_ids, :province_id, :passport, :patient_contact, :deag_reviewed, :diagnosis, :confirmation_date_from, :confirmation_date_to, :travel_history)
    end
  end
end
