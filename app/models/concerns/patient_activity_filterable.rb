module PatientActivityFilterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filters(params)
      results = self.where(nil)
      filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end

    def filters_user_wise_activities(params)
      results = self.where(nil)
      filtering_params_for_user_wise_activities(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end
    
    def filtering_params(params)
      params.slice(:patient_tag, :department, :place, :uc, :from, :to, :tehsil_id, :district_id, :tag_id, :act_tag, :patient_id, :provisional_diagnosis, :datefrom, :dateto, :user_id, :tehsil_ids, :tpv_datefrom, :act_tag_patient, :multi_department)
    end

    def filtering_params_for_user_wise_activities(params)
      params.slice( :uc, :department, :datefrom, :dateto, :tag_id, :district_id, :tehsil_id, :user_id, :mobile_user_ids, :multi_department, :tehsil_ids)
    end
  end
end