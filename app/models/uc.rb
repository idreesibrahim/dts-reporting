# == Schema Information
#
# Table name: ucs
#
#  id          :bigint           not null, primary key
#  uc_name     :string
#  district_id :integer
#  tehsil_id   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Uc < ApplicationRecord

	scope :filter_by_province_id, ->(data){data.present? ? (where("ucs.province_id =?", data) ) : where("true")}
	scope :filter_by_district_id, ->(data){data.present? ? (where("ucs.district_id =?", data) ) : where("true")}
	scope :filter_by_tehsil_id, ->(data){data.present? ? (where("ucs.tehsil_id =?", data) ) : where("true")}
	scope :filter_by_uc, ->(data){data.present? ? (where("ucs.id =?", data) ) : where("true")}

	## validations
	validates :uc_name, presence: {message: "Please enter Uc Name"}, uniqueness: {scope: [:district_id, :tehsil_id], message: "Uc Should be unique"}

	belongs_to :province
	belongs_to :district
	belongs_to :tehsil
	has_and_belongs_to_many :mobile_users, join_table: "mobile_user_ucs"
	
	## remove extra spaces 
	auto_strip_attributes :uc_name, squish: true
	## callbacks

	before_save :titleize_data

	def titleize_data
		self.province_id = (self.district.present? ?  self.district.province.id : nil)
		# self.uc_name = self.uc_name.try(:titleize)
	end
end
