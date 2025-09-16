class PatientAudited < ApplicationRecord
	include PatientAuditedFilterable

	scope :filter_by_district_id, ->(data){where("patient_activities.district_id =?", data)}
	scope :filter_by_tehsil_id, ->(data){where("patient_activities.tehsil_id =?", data)}
	scope :filter_by_department, ->(data){where("patient_activities.department_id =?", data)}
	scope :filter_by_from, ->(data){where("patient_auditeds.created_at::DATE >=?", Time.parse("#{data.to_date}") )}
	scope :filter_by_to, ->(data){where("patient_auditeds.created_at::DATE <=?", Time.parse("#{data.to_date}") )}

	has_one :picture, :as => :pictureable
	belongs_to :patient_activity

	def is_satisfactory?
		(larvae_found == false or larvae_found == '' or larvae_found == nil) and (response_conducted_at_place == true and sop_followed == true)
	end
end
