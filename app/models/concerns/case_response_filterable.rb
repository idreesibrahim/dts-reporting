module CaseResponseFilterable
    extend ActiveSupport::Concern
  
    module ClassMethods
      def filters(params)
        results = self.where(nil)
        filtering_params(params).each do |key, value|
          results = results.public_send("filter_by_#{key}", value) if value.present?
        end
        results
      end
      def filters_combined_map(params)
        results = self.where(nil)
        filtering_params_combined_map(params).each do |key, value|
          results = results.public_send("filter_by_#{key}", value) if value.present?
        end
        results
      end
      
      def filtering_params(params)
        params.slice(:id, :tehsil_id, :uc_id, :tag_id, :district_id, :department_id, :datefrom, :dateto, :larva_source, :case_response_complete, :username)
      end

      def filtering_params_combined_map(params)
        params.slice(:department, :uc, :tag, :datefrom, :dateto, :tag_ids)
      end

    end
  end