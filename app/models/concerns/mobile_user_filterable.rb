module MobileUserFilterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filters(params)
      results = self.where(nil)
      filtering_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end

    def filters_by_users(params)
      results = self.where(nil)
      filtering_by_users_params(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end
    
    def filter_by_user_wise_larva_report(params)
      results = self.where(nil)
      filterering_by_user_wise_larva_report(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end

    def filter_by_department_wise_dormancy(params)
      results = self.where(nil)
      filtering_by_department_wise_dormancy(params).each do |key, value|
        results = results.public_send("filter_by_#{key}", value) if value.present?
      end
      results
    end

    def filtering_params(params)
      params.slice(:username, :district_id, :tehsil_id, :department, :status, :tehsil, :role,:sub_department, :parent_department, :created_date_from, :created_date_to, :updated_date_from, :updated_date_to,
      :active_date_from, :active_date_to, :inactive_date_from, :inactive_date_to)
    end

    def filtering_by_users_params(params)
      params.slice(:username, :district_id, :tehsil_id, :department, :status, :tehsil_ids)
    end

    def filterering_by_user_wise_larva_report(params)
      params.slice(:district_id, :tehsil_id, :department, :status, :parent_department)
    end

    def filtering_by_department_wise_dormancy(params)
      params.slice(:district_id, :tehsil_id, :department)
    end
  end
end