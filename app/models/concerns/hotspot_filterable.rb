module HotspotFilterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filters(params)
      results = self.where(nil)
      filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end
    def filters_sumary_wise_count(params)
      results = self.where(nil)
      summary_wise_filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end

    def filters_hotspot_location_map(params)
      results = self.where(nil)
      hotspot_location_map_filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end

    def filters_popup_hotspot_location_map(params)
      results = self.where(nil)
      popup_hotspot_location_map_filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end



    def filtering_params(params)
      params.slice(
                  :tag_id,
                  :tehsil_id,
                  :status,
                  :district_id,
                  :uc_id,
                  :from,
                  :to,
                  :uc,
                  :hotspot_status,
                  :h_name,
                  :hotspot_from_archive,
                  :hotspot_to_archive,
                  :hotspot_from_y2022_m1to3,
                  :hotspot_to_y2022_m1to3,
                  :hotspot_from_y2022_m4to6,
                  :hotspot_to_y2022_m4to6,
                  :hotspot_from_y2022_m7to9,
                  :hotspot_to_y2022_m7to9,
                  :hotspot_from_y2022_m10to12,
                  :hotspot_to_y2022_m10to12,
                  :hotspot_from_y2023_m1to3,
                  :hotspot_to_y2023_m1to3,
                  :hotspot_from_y2023_m4to6,
                  :hotspot_to_y2023_m4to6,
                  :hotspot_from_y2023_m7to9,
                  :hotspot_to_y2023_m7to9,
                  :hotspot_from_y2023_m10to12,
                  :hotspot_to_y2023_m10to12,
                  :hotspot_from_y2024_m1to3,
                  :hotspot_to_y2024_m1to3,
                  :hotspot_from_y2024_m4to6,
                  :hotspot_to_y2024_m4to6,
                  :hotspot_from_y2024_m7to9,
                  :hotspot_to_y2024_m7to9,
                  :hotspot_from_y2024_m10to12,
                  :hotspot_to_y2024_m10to12,
                  :hotspot_from_y2025_m1to3,
                  :hotspot_to_y2025_m1to3,
                  :hotspot_from_y2025_m4to6,
                  :hotspot_to_y2025_m4to6,
                  :active_date_from,
                  :active_date_to,
                  :inactive_date_from,
                  :inactive_date_to
              )
    end
    def summary_wise_filtering_params(params)
      params.slice(
                  :hotspot_district_id,
                  :hotspot_tag_id,
                  :hotspot_tehsil_id,
                  :hotspot_from,
                  :hotspot_to,
                  :uc,
                  :hotspot_status,
                  :hotspot_from_archive,
                  :hotspot_to_archive,
                  :hotspot_from_y2022_m1to3,
                  :hotspot_to_y2022_m1to3,
                  :hotspot_from_y2022_m4to6,
                  :hotspot_to_y2022_m4to6,
                  :hotspot_from_y2022_m7to9,
                  :hotspot_to_y2022_m7to9,
                  :hotspot_from_y2022_m10to12,
                  :hotspot_to_y2022_m10to12,
                  :hotspot_from_y2023_m1to3,
                  :hotspot_to_y2023_m1to3,
                  :hotspot_from_y2023_m4to6,
                  :hotspot_to_y2023_m4to6,
                  :hotspot_from_y2023_m7to9,
                  :hotspot_to_y2023_m7to9,
                  :hotspot_from_y2023_m10to12,
                  :hotspot_to_y2023_m10to12,
                  :hotspot_from_y2024_m1to3,
                  :hotspot_to_y2024_m1to3,
                  :hotspot_from_y2024_m4to6,
                  :hotspot_to_y2024_m4to6,
                  :hotspot_from_y2024_m7to9,
                  :hotspot_to_y2024_m7to9,
                  :hotspot_from_y2024_m10to12,
                  :hotspot_to_y2024_m10to12,
                  :hotspot_from_y2025_m1to3,
                  :hotspot_to_y2025_m1to3,
                  :hotspot_from_y2025_m4to6,
                  :hotspot_to_y2025_m4to6,
                )
    end

    def popup_hotspot_location_map_filtering_params(params)
      params.slice(
        :hotspot_id,
        :hotspot_distance,
        :hotspot_distance1,
        :hotspot_district_id,
        :hotspot_tehsil_id,
        :hotspot_tag_id,
        :user_id,
        :hotspot_from,
        :hotspot_to
      )
    end

    def hotspot_location_map_filtering_params(params)
      params.slice(
        :hotspot_id,
        :hotspot_distance,
        :hotspot_distance1,
        :hotspot_district_id,
        :hotspot_tehsil_id,
        :hotspot_tag_id,
        :user_id,
        :hotspot_from,
        :hotspot_to
      )
    end
  end
end
