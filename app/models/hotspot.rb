# == Schema Information
#
# Table name: hotspots
#
#  id           :bigint           not null, primary key
#  tehsil       :string
#  uc           :string
#  address      :string
#  tag          :string
#  description  :string
#  hotspot_name :string
#  lat          :string
#  long         :string
#  district_id  :integer
#  district     :string
#  is_active    :boolean
#  tehsil_id    :integer
#  uc_id        :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tag_id       :integer
#  contact_no   :string
#
class Hotspot < ApplicationRecord
	include HotspotFilterable
	## associations

	## optional
	has_many :activities, class_name: 'SimpleActivity'

	## for get all tables simple activities
	has_many :simple_activities
	has_many :archived21_simple_activities
	has_many :simple_activities_y22_m1to3s
	has_many :simple_activities_y22_m4to6s
	has_many :simple_activities_y22_m10to12s
	has_many :simple_activities_y23_m1to3s
	has_many :simple_activities_y23_m4to6s
	has_many :simple_activities_y23_m10to12s
	has_many :simple_activities_y24_m1to3s
	has_many :simple_activities_y24_m4to6s
	has_many :simple_activities_y24_m7to9s
	has_many :simple_activities_y24_m10to12s
	has_many :simple_activities_y25_m1to3s
	has_many :simple_activities_y25_m4to6s

	has_many :department_tags, :primary_key => 'tag_id', :foreign_key => "tag_id", :class_name => "DepartmentTag"
	belongs_to :updated_by, class_name: 'User', primary_key: "id", foreign_key: 'hotspot_updated_by', optional: true
	belongs_to :mobile_user_created_by, class_name: 'MobileUser', foreign_key: 'mobile_user_created_id', optional: true
	belongs_to :mobile_user_updated_by, class_name: 'MobileUser', foreign_key: 'mobile_user_updated_id', optional: true
	## scopes
	scope :active, -> { where("hotspots.is_active is true") }
	scope :filter_by_hotspot_id, ->(data){data.present? ? (where("hotspots.id =?", data) ) : where("true")}
	scope :get_tehsils, ->(tehsils){where("hotspots.tehsil_id IN(?)", tehsils)}
	scope :get_departments, ->(departments){where("department_tags.department_id =?", departments)}
	scope :filter_by_tehsil_id, ->(data){data.present? ? (where("tehsil_id =?", data) ) : where("true")}
	scope :filter_by_district_id, ->(data){data.present? ? (where("district_id =?", data) ) : where("true")}
	scope :filter_by_uc_id, ->(data){data.present? ? (where("hotspots.uc_id =?", data) ) : where("true")}
	scope :filter_by_uc, ->(data){data.present? ? (where("hotspots.uc_id =?", data) ) : where("true")}
	scope :filter_by_status, ->(data){data.present? ? (where("is_active is #{data}" ) ) : where("true")}
	scope :filter_by_hotspot_status, ->(data){data.present? ? (where("hotspots.is_active is #{data}" ) ) : where("true")}
	scope :filter_by_tag_id, ->(data){data.present? ? (where("tag_id IN (?)", data) ) : where("true")}
	scope :filter_by_from, ->(data){where("created_at >=?", Time.parse("#{data.to_datetime}").beginning_of_day )}
	scope :filter_by_to, ->(data){where("created_at <=?", Time.parse("#{data.to_datetime}").end_of_day )}
	scope :filter_by_h_name, ->(data){where("lower(hotspot_name) like ?", "%#{data.try(:downcase)}%")}

	## hotspot suummary wise count
	scope :filter_by_hotspot_district_id, ->(data){data.present? ? where("hotspots.district_id =?", data) : where("true")}
	scope :filter_by_hotspot_tehsil_id, ->(data){data.present? ? where("hotspots.tehsil_id =?", data) : where("true")}
	scope :filter_by_hotspot_tag_id, ->(data){data.present? ? (where("hotspots.tag_id IN (?)", data) ) : where("true")}
	scope :filter_by_hotspot_from, ->(data){where("simple_activities.created_at >= ?", data )}
	scope :filter_by_hotspot_to, ->(data){where("simple_activities.created_at <= ?", data )}
	scope :filter_by_hotspot_distance, ->(data){where(self.distance_convert_into_number(data))}
	scope :filter_by_hotspot_distance1, ->(data){where(self.distance_convert_into_number(data))}
	scope :filter_by_user_id, ->(data){data.present? ? where("simple_activities.user_id =?", data) : where("true")}

	scope :filter_by_hotspot_from_archive, ->(data){where("archived21_simple_activities.created_at >= ?", data )}
	scope :filter_by_hotspot_to_archive, ->(data){where("archived21_simple_activities.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2022_m1to3, ->(data){where("simple_activities_y22_m1to3.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2022_m1to3, ->(data){where("simple_activities_y22_m1to3.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2022_m4to6, ->(data){where("simple_activities_y22_m4to6.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2022_m4to6, ->(data){where("simple_activities_y22_m4to6.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2022_m7to9, ->(data){where("simple_activities_y22_m7to9.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2022_m7to9, ->(data){where("simple_activities_y22_m7to9.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2022_m10to12, ->(data){where("simple_activities_y22_m10to12.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2022_m10to12, ->(data){where("simple_activities_y22_m10to12.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2023_m1to3, ->(data){where("simple_activities_y23_m1to3.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2023_m1to3, ->(data){where("simple_activities_y23_m1to3.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2023_m4to6, ->(data){where("simple_activities_y23_m4to6.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2023_m4to6, ->(data){where("simple_activities_y23_m4to6.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2023_m7to9, ->(data){where("simple_activities_y23_m7to9.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2023_m7to9, ->(data){where("simple_activities_y23_m7to9.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2023_m10to12, ->(data){where("simple_activities_y23_m10to12.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2023_m10to12, ->(data){where("simple_activities_y23_m10to12.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2024_m1to3, ->(data){where("simple_activities_y24_m1to3s.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2024_m1to3, ->(data){where("simple_activities_y24_m1to3s.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2024_m4to6, ->(data){where("simple_activities_y24_m4to6s.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2024_m4to6, ->(data){where("simple_activities_y24_m4to6s.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2024_m7to9, ->(data){where("simple_activities_y24_m7to9.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2024_m7to9, ->(data){where("simple_activities_y24_m7to9.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2024_m10to12, ->(data){where("simple_activities_y24_m10to12.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2024_m10to12, ->(data){where("simple_activities_y24_m10to12.created_at <= ?", data )}

	scope :filter_by_active_date_from, ->(data) {data.present? ? where("hotspots.active_date >= ?", data) : where("true") }
	scope :filter_by_active_date_to, ->(data) {data.present? ? where("hotspots.active_date <= ?", data) : where("true")}

	scope :filter_by_inactive_date_from, ->(data) {data.present? ? where("hotspots.inactive_date >= ?", data) : where("true")}
	scope :filter_by_inactive_date_to, ->(data) {data.present? ? where("hotspots.inactive_date <= ?", data) : where("true")}

	scope :filter_by_hotspot_from_y2025_m1to3, ->(data){where("simple_activities_y25_m1to3s.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2025_m1to3, ->(data){where("simple_activities_y25_m1to3s.created_at <= ?", data )}

	scope :filter_by_hotspot_from_y2025_m4to6, ->(data){where("simple_activities_y25_m4to6s.created_at >= ?", data )}
	scope :filter_by_hotspot_to_y2025_m4to6, ->(data){where("simple_activities_y25_m4to6s.created_at <= ?", data )}



	before_save :save_hotspot_attributes

	def save_hotspot_attributes
		self.district = self.district_id.present? ? District.find(self.district_id).try(:district_name) : nil
		self.tehsil = self.tehsil_id.present? ? Tehsil.find(self.tehsil_id).try(:tehsil_name) : nil
		self.uc = self.uc_id.present? ? Uc.find(self.uc_id).try(:uc_name) : nil
		self.tag = self.tag_id.present? ? Tag.find(self.tag_id).try(:tag_name) : nil
		self.active_date = Time.now if (self.is_active.present? and self.is_active_changed? and self.is_active)
		self.inactive_date = Time.now if (self.is_active.present? || self.is_active.class == FalseClass) and ( self.is_active_changed? and !self.is_active)
	end

	def self.hotspot_json(hotspot)
		{
			"hotspot_id" => hotspot.id,
			"town" => hotspot.tehsil,
			"town_id" => hotspot.tehsil_id,
			"uc" => hotspot.uc,
			"uc_id" => hotspot.uc_id,
			"tag" => hotspot.tag,
			"tag_id" => hotspot.tag_id,
			"address" => hotspot.address,
			"description" => hotspot.description,
			"hotspot_name" => hotspot.hotspot_name,
			"contact_no" => hotspot.contact_no,
			"is_tagged"=> hotspot.is_tagged,
			# "manage_hotspot" => hotspot.manage_hotspot,
			"lat"=>hotspot.lat,
			"long"=> hotspot.long,
			"radius"=>hotspot.radius
		}
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
