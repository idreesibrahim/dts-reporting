class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  rescue_from CanCan::AccessDenied do |exception|
    IdiCaptcha::Captcha.generate(session)
    redirect_to root_url, :alert => exception.message
  end
	protected

  def after_sign_in_path_for(resource)
    stored_location = stored_location_for(resource)
    if stored_location
      stored_location
    else
      case
      when resource.admin? || resource.master_user? || resource.dpc_user? || resource.phc_user? || resource.master_user?
        #patients_path
      when resource.hospital_user? || resource.hospital_supervisor?
        #home_hospital_users_path
      when resource.lab_user? || resource.lab_supervisor?
        #home_lab_users_path
      when resource.department_user?
        #heat_map_path
      when resource.tehsil_user?
        #summary_of_activities_town_wise_path
      when resource.provisional_incharge?
        #home_provincial_path
      when resource.is_user_registration?
        #mobile_users_path
      else
        #patients_path
      end
      reports_dashboard_path
    end
  end
  
  def after_sign_out_path_for(resource)
    new_user_session_path
  end
end
