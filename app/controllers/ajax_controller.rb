class AjaxController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :get_type_wise_title, only: [:google_map_popup_data, :positive_larvae_map_pop_up, :positive_larvae_map_pop_up_case_response, :hotspot_google_map_popup_data, :tpv_popup_data]
  include ApplicationHelper

  def nfs_picture
    picture_url = params[:picture_url]
    begin
      send_file File.join("#{picture_url}"), :disposition => 'inline'
    rescue
      send_file File.join("/home/dentracking/dengue/public/tag_image.png")
    end
  end
end
