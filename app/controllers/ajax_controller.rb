class AjaxController < ApplicationController
  skip_before_action :verify_authenticity_token
  # before_action :get_type_wise_title, only: [:google_map_popup_data, :positive_larvae_map_pop_up, :positive_larvae_map_pop_up_case_response, :hotspot_google_map_popup_data, :tpv_popup_data]
  include ApplicationHelper

  def nfs_picture
    picture_url = params[:picture_url]
    begin
      send_file File.join("#{picture_url}"), :disposition => 'inline'
    rescue
      send_file File.join("/home/dentracking/dengue/public/tag_image.png")
    end
  end
  def populate_tehsil
    @tehsils = []
    @ucs = []
    if params[:district].present?
      if params[:district] != 'All'
        @tehsils = Tehsil.accessible_by(current_ability, :read).where(district_id: params[:district]).order("tehsil_name ASC").collect{|p| [p.tehsil_name, p.id]}
      else
        @tehsils = Tehsil.select("id,tehsil_name").order("tehsil_name ASC").collect{|p| [p.tehsil_name]}
      end
    end

    @tehsils = @tehsils.uniq      #ignoring repeating elements

    respond_to do |format|
      format.json {render :json => @tehsils.to_json}
    end
  end
  def populate_uc
    if params[:town].present?
      if params[:town] != 'All'
        @ucs = Uc.accessible_by(current_ability, :read).where('tehsil_id = ?', params[:town].downcase).order("uc_name ASC").collect{|p| [p.uc_name,p.id]}
      else
        @ucs = Uc.select("id,uc_name").order("uc_name ASC").collect{|p| [p.uc_name]}
      end
    end

    #ignoring repeating elements
    @ucs = @ucs.uniq
    respond_to do |format|
      format.json {render :json => @ucs.to_json}
    end
  end
  def populate_sub_departments
    render json: new_departments_list
  end
end
