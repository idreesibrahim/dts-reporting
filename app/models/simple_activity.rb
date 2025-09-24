### if we want to add new archive table
## steps 1: 
# Generate the table by running following command in psql or pgadmin or migration 

#	create table {{TABLE_NAME}} ( like simple_activities including all);
#	insert into {{TABLE_NAME}} (select * from simple_activities where created_at > DATE '{{from_date}}' AND created_at < DATE '{{to_date}}');

# replace TABLE_NAME WITH as you like
# set from_date and to_date as you want to fetch data from simple_activities and want to insert into archive table.

## steps 2:
## in hotspot added scopes according to your new archive table for example.

#scope :filter_by_hotspot_from_#{{TABLE_NAME}}, ->(data){where("#{{TABLE_NAME}}.created_at >= ?", data )}
#scope :filter_by_hotspot_to_#{{TABLE_NAME}}, ->(data){where("#{{TABLE_NAME}}.created_at <= ?", data )}

## in concerns folder go HotspotFilterable file and added two scopes hotspot_from_#{{TABLE_NAME}} and hotspot_to_#{{TABLE_NAME}}

## steps 3:
#in application helper 
# add new value in json under periods_info method

## step 4:
#add condition in jquyery
#go assets folder and search period.js
#add condition according to table


class SimpleActivity < ApplicationRecord
	include SimpleActivityFilterable

	## scopes
	scope :ascending, ->{order("simple_activities.created_at DESC")}
	scope :filter_by_tag, ->(data){where("simple_activities.tag_id IN(?)", data)}
	scope :filter_by_sub_department, ->(data){data.present? ? where("simple_activities.department_id =?", data) : where("true")}
	scope :filter_by_department, ->(data){data.present? ? where("simple_activities.department_id =?", data) : where("true")}
	scope :filter_by_parent_department, ->(data){data.present? ? where("simple_activities.parent_department_id =?", data) : where("true")}
	scope :filter_by_multi_department, ->(data){where("simple_activities.department_id IN(?)", data.split(","))}
	scope :filter_by_io_action, ->(data){where("simple_activities.io_action =?", data)}
	
	scope :is_larva_found, ->{where("simple_activities.larva_found is true")}
	scope :is_not_larva_found, ->{where("simple_activities.larva_found is false")}
	scope :filter_by_is_bogus, ->(data){data.present? ? where( data == "true" ? "simple_activities.is_bogus is true" : "simple_activities.is_bogus is not true" ) : where("true")}

	scope :filter_by_uc, ->(data){ data.present? ? where("simple_activities.uc_id =?", data) : where("true")}
	scope :filter_by_tehsil_id, ->(data){data.present? ? where("simple_activities.tehsil_id =?", data) : where("true")}
	scope :filter_by_tehsil_ids, ->(data){where("simple_activities.tehsil_id IN(?)", data)}
	scope :filter_by_district_id, ->(data){data.present? ? where("simple_activities.district_id =?", data) : where("true")}
	scope :filter_by_tag_id, ->(data){data.present? ? (where("simple_activities.tag_id IN (?)", data) ) : where("true")}
	scope :filter_by_act_tag, ->(data){data.present? ? (where("simple_activities.tag_id =?", data) ) : where("true")}
	scope :filter_by_larva_type, ->(data){where("simple_activities.larva_type = ?", data)}
	scope :filter_by_user_id, ->(data){where("simple_activities.user_id =?", data)}
	scope :filter_by_status, ->(data){where("mobile_users.status =?", data)}
	scope :filter_by_username, ->(data){where("lower(mobile_users.username) like ?", "%#{data}%".downcase)}
	
	scope :filter_by_mobile_user_ids, ->(data){data.present? ? (where("simple_activities.user_id IN(?)", data)) : where("true")}
	
	scope :filter_by_from, ->(data){ data.present? ? (where("simple_activities.created_at::DATE >=?", Time.parse("#{data.to_date}").beginning_of_day ))   : where("true")}
	scope :filter_by_to, ->(data){ data.present? ? (where("simple_activities.created_at::DATE <=?", Time.parse("#{data.to_date}").end_of_day )) : where("true")}

	scope :filter_by_datefrom, ->(data){data.present? ? (where("simple_activities.created_at >= ?", data) ) : where("true")}
	scope :filter_by_dateto, ->(data){data.present? ? (where("simple_activities.created_at <= ?", data) ) : where("true")}

	## hotspots
	scope :filter_by_hotspot_id, ->(data){data.present? ? where("simple_activities.hotspot_id =?", data) : where("true")}
	scope :filter_by_hotspot_district_id, ->(data){data.present? ? where("simple_activities.district_id =?", data) : where("true")}
	scope :filter_by_hotspot_tehsil_id, ->(data){data.present? ? where("simple_activities.tehsil_id =?", data) : where("true")}
	scope :filter_by_hotspot_tag_id, ->(data){data.present? ? (where("simple_activities.tag_id IN (?)", data) ) : where("true")}	
	scope :filter_by_hotspot_from, ->(data){where("simple_activities.created_at >= ?", data )}
	scope :filter_by_hotspot_to, ->(data){where("simple_activities.created_at <= ?", data )}
	scope :filter_by_hotspot_status, ->(data){data.present? ? (where("hotspots.is_active is #{data}" ) ) : where("true")}
	scope :filter_by_hotspot_distance1, ->(data){where(self.distance_convert_into_number(data))}
	scope :filter_by_hotspot_distance, ->(data){data.present? ? where("simple_activities.hotspot_distance =?", data) : where("true")}
	
	scope :positive_and_negative, ->{where(larva_type: [:positive, :negative])}
	scope :all_larvae, ->{where(larva_type: [:positive, :negative, :repeat])}
	
	## Category Wise
	scope :is_hotspots, ->{where("simple_activities.tag_category_id =?", 1)}
	scope :is_patient, ->{where("simple_activities.tag_category_id =?", 2)}
	scope :is_larvae, ->{where("simple_activities.tag_category_id =?", 3)}
	scope :is_vector_surveillance, ->{where("simple_activities.tag_category_id =?", 6)}
	scope :filter_by_tpv_datefrom, ->(data){where("simple_activities.created_at between ? and ?", data.try(:to_datetime).beginning_of_day, data.try(:to_datetime).end_of_day)}
	
	## enums
	enum :larva_type, [:positive, :negative, :repeat]
	enum :io_action, [:indoor, :outdoor]
	## associations
	has_one :picture, :as => :pictureable
	
	# belongs_to :user, optional: true
	belongs_to :user, :primary_key => 'id', :foreign_key => "user_id", :class_name => "MobileUser" , optional: true
	belongs_to :tag_category, optional: true
	belongs_to :tag, optional: true
	belongs_to :hotspot, optional: true
	
	belongs_to :district, optional: true
	belongs_to :tehsil, optional: true
	belongs_to :uc, optional: true
	belongs_to :department, optional: true
		
	#validations
	validates :user_id, presence: {message: 'User should be required'}
	validates :tag_category_id, presence: {message: 'Category should be required'}
	validates :tag_id, presence: {message: 'Tag should be required'}	

	#validations
	validates :latitude, presence: {message: 'Latitude should be required'}
	validates :longitude, presence: {message: 'Longitude should be required'}
	validates :activity_time, presence: {message: 'Activity Time should be required'}

	validates :larva_type, inclusion: { in: larva_types.keys, allow_blank: true, message: 'Please select correct Larva Type' }
	validates :io_action, inclusion: { in: io_actions.keys, allow_blank: true, message: 'Please select correct IO Action' }

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
	
	before_create :set_parent_department
	def set_parent_department
		if self.department_id.present?
			if self.department.parent_department.present?
				self.parent_department_name = self.department.try(:parent_department_name)
				self.parent_department_id = self.department.try(:parent_department_id)
			end
		end
	end

	before_save :titleize_data		
	def titleize_data
		self.uc_name = self.uc_name.try(:titleize)
		self.tag_category_name = self.tag_category_name.try(:titleize)
		self.tag_name = self.tag_name.try(:titleize)
		self.tehsil_name = self.tehsil_name.try(:titleize)
		self.comment = self.comment.try(:titleize)
		self.description = self.description.try(:titleize)
	end
	
	before_save :last_visited_date_of_hotspot
	def last_visited_date_of_hotspot
		if hotspot_id.present?
			if hotspot.present?
				hotspot.last_visited = Time.now
				hotspot.save(validate:  false)
			end
		end
	end
	def save_picture(m_before_picture, m_after_picture)
		if create_picture(before_picture: m_before_picture, after_picture: m_after_picture)
			return reload_picture
		end
		nil
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

	def self.distance_convert_into_number(data)
		case data
		when 'less_than_200'
			return "simple_activities.hotspot_distance < 200"
		when 'between_200_to_500'
			return "simple_activities.hotspot_distance BETWEEN 200 AND 500"
		when 'between_500_to_1000'
			return "simple_activities.hotspot_distance BETWEEN 500 AND 1000"
		when 'greather_than_1000'
			return "simple_activities.hotspot_distance > 1000"
		else
			return "true"
		end
	end
end
