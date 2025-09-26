# == Schema Information
#
# Table name: tag_categories
#
#  id               :bigint           not null, primary key
#  category_name    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  urdu             :string
#  m_category_id    :integer
#  category_name_en :string
#
class TagCategory < ApplicationRecord
	## validations
	has_many :tags, dependent: :destroy
	validates :category_name, presence: true, uniqueness: true

	## remove extra spaces 
	auto_strip_attributes :category_name, squish: true
	
	## callbacks
	before_save :titleize_data

	def titleize_data
		self.category_name = self.category_name.try(:titleize)
	end
end
