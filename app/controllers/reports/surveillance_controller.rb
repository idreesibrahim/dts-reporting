# app/controllers/reports/surveillance_controller.rb
module Reports
  class SurveillanceController < ApplicationController
    before_action :authenticate_user!
    include ApplicationHelper
    before_action :get_table_from_period, only: [:simple_activity_line_list, :mark_act_bogus, :bogus_activity_line_list]
    layout "report"  # this will use app/views/layouts/report.html.erb

    def line_list
      authorize! :read, PatientActivity

      per_page = per_page_items(100000)
      
      if params.has_key? :datefrom
        @activities = PatientActivity.accessible_by(current_ability, :read).includes(:patient, :user).filters(params).ascending.paginate(:page => params[:page], :per_page => per_page)
      else
        @activities = []
      end
      respond_to do |format|
            format.html 
            format.xls
      end
    end
    
    def simple_activity_line_list
      authorize! :read, SimpleActivity
      per_page = per_page_items(100000)
      if params[:submitted_by].present?
        user = MobileUser.find_by_username(params[:submitted_by])
        if user.present?
          params[:user_id] = user.id
        else
          params[:user_id] = 0
        end
      end
      if params.has_key? :datefrom
        @activities = @activity_table.select("
                                    #{@table_name}.ID,
                                    #{@table_name}.DISTRICT_NAME,
                                    #{@table_name}.TEHSIL_NAME,
                                    #{@table_name}.UC_NAME,
                                    #{@table_name}.DEPARTMENT_NAME,
                                    #{@table_name}.DEPARTMENT_ID,
                                    #{@table_name}.TAG_NAME,
                                    #{@table_name}.hotspot_id,
                                    #{@table_name}.LARVA_FOUND,
                                    #{@table_name}.LARVA_TYPE,
                                    #{@table_name}.LATITUDE,
                                    #{@table_name}.LONGITUDE,
                                    #{@table_name}.CREATED_AT,
                                    #{@table_name}.IS_BOGUS,
                                    #{@table_name}.USER_ID,
                                    #{@table_name}.BEFORE_PICTURE,
                                    #{@table_name}.AFTER_PICTURE,
                                    #{@table_name}.PDIF_TIME")
                                    .accessible_by(current_ability, :read)
                                    .includes(:user, :hotspot)
                                    .filters(params)
                                    .ascending
                                    .paginate(:page => params[:page], :per_page => per_page)
      else
        @activities = []
		  end
	  end

    def mark_act_bogus
      simple_activity = @activity_table.find(params[:activity_id])
        authorize! :mark_act_bogus, simple_activity
        if simple_activity.is_bogus == false or simple_activity.is_bogus == nil
            simple_activity.update_attributes(:is_bogus => true)
        end

        current_page = params[:page].present? ? params[:page] : "1"

        respond_to do |format|
            format.html { redirect_back fallback_location: root_path, notice: 'Activity has been marked bogus successfully.' }
        end
	  end

    def bogus_activity_line_list
      authorize! :read, SimpleActivity

      per_page = per_page_items(10)

      if params.has_key? :datefrom
        @activities = @activity_table.select("#{@table_name}.id, #{@table_name}.district_name, #{@table_name}.tehsil_name, #{@table_name}.uc_name, #{@table_name}.department_name, #{@table_name}.tag_name, #{@table_name}.larva_found, #{@table_name}.larva_type, #{@table_name}.latitude, #{@table_name}.longitude, #{@table_name}.created_at, #{@table_name}.is_bogus, #{@table_name}.user_id, #{@table_name}.before_picture, #{@table_name}.after_picture").accessible_by(current_ability, :read).where("is_bogus is true").filters(params).ascending.paginate(:page => params[:page], :per_page => per_page)
      else
        @activities = []
      end
    end

	end

end
