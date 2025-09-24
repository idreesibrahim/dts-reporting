module SimpleActivityFilterable
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
    def filters_hotspots(params)
      results = self.where(nil)
      filtering_hotspots_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end
    def filters_dormancy(params)
      results = self.where(nil)
      filtering_params_dormancy(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end
    def filtering_params(params)
      params.slice(:act_tag, :uc, :io_action, :from, :to, :tag_id, :district_id, :tehsil_id, :user_id, :mobile_user_ids, :multi_department, :larva_type, :username, :status, :datefrom, :dateto, :tehsil_ids, :hotspot_status,:parent_department,:sub_department, :department, :is_bogus, :hotspot_distance, :tpv_datefrom)
    end
    def filtering_params_for_user_wise_activities(params)
      params.slice(:act_tag, :uc, :department, :io_action, :datefrom, :dateto, :tag_id, :district_id, :tehsil_id, :user_id, :mobile_user_ids, :multi_department, :larva_type, :tehsil_ids, :hotspot_status)
    end
    def filtering_hotspots_params(params)
      params.slice(:act_tag, :hotspot_distance, :hotspot_district_id, :hotspot_tehsil_id, :hotspot_tag_id, :hotspot_from, :hotspot_to, :uc, :hotspot_status, :hotspot_id, :user_id)
    end
    def filtering_params_dormancy(params)
      params.slice(:act_tag, :uc, :department, :io_action, :tag_id, :district_id, :tehsil_id, :user_id, :mobile_user_ids, :multi_department, :larva_type, :username, :status, :tehsil_ids, :hotspot_status)
    end
  end
end