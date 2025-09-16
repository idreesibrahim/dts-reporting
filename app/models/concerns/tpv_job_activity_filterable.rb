module TpvJobActivityFilterable
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
      params.slice(:type, :job_id, :tpv_date, :district_id, :tehsil_id, :uc_id, :department_id, :tpv_datefrom, :tpv_dateto, :department_category, :tpv_audit_id, :filter_type, :dep_category_id)
    end
  end
end
