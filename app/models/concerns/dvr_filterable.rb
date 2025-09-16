module DvrFilterable
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
      params.slice(:dvr_id, :status, :district_id, :tehsil_id, :department_id, :dvr_category_id, :datefrom, :dateto, :updated_from, :updated_to, :mobile_user_id)
    end

    def nested_filtering(params)
      results = self.where(nil)
      nested_filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end
    def nested_filtering_params(params)
      params.slice(:ndistrict_id, :ntehsil_id, :ndepartment_id, :department_id, :ndvr_category_id, :nstatus, :datefrom, :dateto)
    end

  end
end
