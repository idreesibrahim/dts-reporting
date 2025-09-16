class Mv::SimpleActivitiesLastDay < ApplicationRecord
  self.table_name = 'simple_activities_last_day'
  include SimpleActivityFilterable
	## enums
	enum larva_type: [:positive, :negative, :repeat]
	enum io_action: [:indoor, :outdoor]
  ## Category Wise
  scope :is_larva_found, ->{where("simple_activities_last_day.larva_found is true")}
  scope :filter_by_district_id, ->(data){data.present? ? where("simple_activities_last_day.district_id =?", data) : where("true")}
	scope :filter_by_tehsil_id, ->(data){data.present? ? where("simple_activities_last_day.tehsil_id =?", data) : where("true")}
  scope :filter_by_uc_ic, ->(data){ data.present? ? where("simple_activities_last_day.uc_id =?", data) : where("true")}
  scope :filter_by_department, ->(data){data.present? ? where("simple_activities_last_day.department_id =?", data) : where("true")}
  scope :is_hotspots, ->{where("simple_activities_last_day.tag_category_id =?", 1)}
	scope :is_patient, ->{where("simple_activities_last_day.tag_category_id =?", 2)}
	scope :is_larvae, ->{where("simple_activities_last_day.tag_category_id =?", 3)}
	scope :is_vector_surveillance, ->{where("simple_activities_last_day.tag_category_id =?", 6)}
	scope :filter_by_tpv_datefrom, ->(data){where("simple_activities_last_day.created_at between ? and ?", data.try(:to_datetime).beginning_of_day, data.try(:to_datetime).end_of_day)}
end