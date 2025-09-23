# app/controllers/reports/surveillance_controller.rb
module Reports
  class SurveillanceController < ApplicationController
    before_action :authenticate_user!
    include ApplicationHelper
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

    
	end

end
