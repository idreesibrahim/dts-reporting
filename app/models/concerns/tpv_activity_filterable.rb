module TpvActivityFilterable
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
      params.slice(:job_id, :district_id, :multidistrict_id, :tehsil_id, :uc_id, :datefrom, :dateto, :filter_type, :dep_category_id)
    end
  end
end