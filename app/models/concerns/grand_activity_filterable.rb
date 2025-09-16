module GrandActivityFilterable
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
      params.slice(:district_id, :tehsil_id, :department_id, :parent_department_id, :user_id, :from, :to)
    end
  end
end
