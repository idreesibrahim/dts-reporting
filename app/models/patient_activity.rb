# == Schema Information
#
# Table name: patient_activities
#
#  id                        :bigint           not null, primary key
#  tag_category_id           :integer
#  tag_category_name         :string
#  awareness                 :boolean
#  removal_bleeding_spot     :boolean
#  elimination_bleeding_spot :boolean
#  patient_spray             :boolean
#  comment                   :text
#  tag_name                  :string
#  tag_id                    :integer
#  app_version               :integer
#  latitude                  :string
#  longitude                 :string
#  activity_time             :datetime
#  os_version_number         :integer
#  os_version_name           :string
#  user_id                   :integer
#  patient_id                :integer
#  uc_name                   :string
#  uc_id                     :integer
#  tehsil_name               :string
#  tehsil_id                 :integer
#  before_picture            :string
#  after_picture             :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  patient_place             :integer
#
class PatientActivity < ApplicationRecord
	include PatientActivityFilterable

	## scopes
	scope :ascending, ->{order("patient_activities.created_at DESC")}
	scope :filter_by_patient_tag, ->(data){where("patient_activities.tag_id =?", data)}
	scope :filter_by_department, ->(data){where("patient_activities.department_id =?", data)}
	scope :filter_by_multi_department, ->(data){where("patient_activities.department_id IN(?)", data.split(","))}
	
	scope :filter_by_uc, ->(data){where("patient_activities.uc_id =?", data)}
	scope :filter_by_tehsil_id, ->(data){where("patient_activities.tehsil_id =?", data)}
	scope :filter_by_tehsil_ids, ->(data){where("patient_activities.tehsil_id IN(?)", data)}
	scope :filter_by_tag_id, ->(data){where("patient_activities.tag_id IN (?)", data)}
	scope :filter_by_act_tag, ->(data){data.present? ? (where("patient_activities.tag_id =?", data) ) : where("true")}
	scope :filter_by_act_tag_patient, ->(data){data.present? ? (where("patient_activities.tag_id =?", data) ) : where("true")}
	scope :filter_by_place, ->(data){where("patient_activities.patient_place =?", data)}
	
	scope :filter_by_from, ->(data){where("patient_activities.created_at::DATE >=?", Time.parse("#{data}") )}
	scope :filter_by_to, ->(data){where("patient_activities.created_at::DATE <=?", Time.parse("#{data}") )}
	scope :is_confirmed, ->{where("patient_activities.provisional_diagnosis =?", 3)}
	scope :filter_by_user_id, ->(data){where("patient_activities.user_id =?", data)}
	scope :filter_by_district_id, ->(data){where("patient_activities.district_id =?", data)}
	scope :filter_by_mobile_user_ids, ->(data){data.present? ? (where("patient_activities.user_id IN(?)", data)) : where("true")}
	scope :filter_by_datefrom, ->(data){data.present? ? (where("patient_activities.created_at >= ?", data) ) : where("true")}
	scope :filter_by_dateto, ->(data){data.present? ? (where("patient_activities.created_at <= ?", data) ) : where("true")}
	scope :is_not_permement_place, ->{where("patient_activities.patient_place !=?", 0)}
	# scope :tehsil, ->(data) {where(tehsil_id: data)}

	## case_response survelence map scopes
	scope :case_response_tags, ->{where("patient_activities.tag_name IN(?)", ['Patient Irs','Patient Surveillance', 'Patient'] )}
	scope :filter_by_patient_id, ->(data){where("patient_activities.patient_id =?", data)}
	scope :filter_by_provisional_diagnosis, ->(data){where("patient_activities.provisional_diagnosis =?", Patient.provisional_diagnoses[data])}
	scope :filter_by_tpv_datefrom, ->(data){where("patient_activities.created_at between ? and ?", data.try(:to_datetime).beginning_of_day, data.try(:to_datetime).end_of_day)}
	scope :patient_irs, ->{where("patient_activities.tag_id =?", 43)}

	scope :filter_by_multi_department, ->(data){where("patient_activities.department_id IN(?)", data.split(","))}

	## enums
	enum :patient_place, %w(permanent workplace residence)
	enum :provisional_diagnosis, { "Non-Dengue": 0, "Probable": 1, "Suspected": 2, "Confirmed": 3}
	## associations
	has_one :picture, :as => :pictureable
	# belongs_to :user, optional: true
	belongs_to :user, :primary_key => 'id', :foreign_key => "user_id", :class_name => "MobileUser" , optional: true
	belongs_to :tag_category, optional: true
	belongs_to :tag, optional: true
	belongs_to :patient, optional: true

	belongs_to :district, optional: true
	belongs_to :tehsil, optional: true
	belongs_to :uc, optional: true
	belongs_to :department, optional: true
		
	#validations
	validates :user_id, presence: {message: 'User should be required'}
	validates :tag_category_id, presence: {message: 'Category should be required'}
	validates :tag_id, presence: {message: 'Tag should be required'}

	validates :latitude, presence: {message: 'Latitude should be required'}
	validates :longitude, presence: {message: 'Longitude should be required'}
	validates :activity_time, presence: {message: 'Activity Time should be required'}

	## remove extra spaces 
	auto_strip_attributes :uc_name, :tag_name, :tehsil_name, :tag_category_name, :comment, :description, squish: true

	## callbacks
	before_save :missing_data
	def missing_data
		self.district_name = self.district.try(:district_name)
		self.tehsil_name = self.tehsil.try(:tehsil_name)
		self.uc_name = self.uc.try(:uc_name)
		self.department_name = self.department.try(:new_dep_name)
	end


	before_save :titleize_data
	def titleize_data
		self.uc_name = self.uc_name.try(:titleize)
		self.tag_name = self.tag_name.try(:titleize)
		self.tehsil_name = self.tehsil_name.try(:titleize)
		self.tag_category_name = self.tag_category_name.try(:titleize)
		self.comment = self.comment.try(:titleize)
		self.description = self.description.try(:titleize)
	end

	def save_picture(m_before_picture, m_after_picture)
		if create_picture(before_picture: m_before_picture, after_picture: m_after_picture)
			return reload_picture
		end
		nil
	end
	def is_patient_irs?
		tag_name == 'Patient Irs'
	end
	def is_irs_patient?
		tag_name == 'Patient'
	end
	# def before_picture
	# 	picture.present? ? get_realtive_path_image(picture.before_picture.url) : ''
	# end
	# def after_picture
	# 	picture.present? ? get_realtive_path_image(picture.after_picture.url) : ''
	# end

	def get_realtive_path_image(url)
		return url.present? ? "#{url}" : ""
	end
end
