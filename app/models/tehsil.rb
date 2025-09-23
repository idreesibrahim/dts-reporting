# == Schema Information
#
# Table name: tehsils
#
#  id          :bigint           not null, primary key
#  tehsil_name :string
#  district_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Tehsil < ApplicationRecord
	## associations
	belongs_to :district, optional: true
  belongs_to :province, optional: true
	has_many :ucs
	has_and_belongs_to_many :mobile_users, join_table: "mobile_user_tehsils"
  ## scops
  scope :punjab, -> { where("province_id IN(?)", punjab_province_ids) }
  scope :other_than_punjab, -> { where("province_id NOT IN(?)", punjab_province_ids) }
	## remove extra spaces
	auto_strip_attributes :tehsil_name, squish: true
	validates :tehsil_name, presence: {message: "Tehsil Name can't be blank"}, uniqueness: {message: "Tehsil Name should be unique", scope: :district_id}
	## callbacks

	# before_save :titleize_data

	# def titleize_data
	# 	self.tehsil_name = self.tehsil_name.try(:titleize)
	# end

  before_save :auto_save_province

  def auto_save_province
    self.province_id = self.district.province_id if self.district_id_changed? and self.district.present?
  end
  def is_punjab_tehsil?
    self.class.punjab_province_ids.include?(self.province_id)
  end
  def self.punjab_province_ids
    [1,2]
  end
  def is_punjab_district_tehsil?(current_district_id)
    district_id == current_district_id
  end
end
