# == Schema Information
#
# Table name: tags
#
#  id              :bigint           not null, primary key
#  tag_name        :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tag_category_id :integer
#  tag_image_url   :string
#  tag_options     :string
#  urdu            :string
#  m_tag_id        :integer
#  m_category_id   :integer
#  tag_name_en     :string
#
class Tag < ApplicationRecord
	include TagFilterable
	## associations
	belongs_to :tag_category
	has_and_belongs_to_many :departments, join_table: "department_tags"

	## validations
	validates :tag_name, presence: true, uniqueness: {scope: :tag_category_id}, allow_nil: true
	
	# Scopes
	scope :ascending, -> { order("tag_name") }
	scope :hotspots_tags, -> { where("m_category_id = ?", 1) }
	scope :filter_by_tag_id, ->(data) { data.present? ? where("tags.id IN (?)", data) : where("true") }
	scope :filter_by_department, ->(data) { data.present? ? joins(:departments).where("department_id = ?", data) : where("true") }

	## remove extra spaces 
	auto_strip_attributes :tag_name, squish: true
	## callbacks
	before_save :titleize_data
		
	def titleize_data
		self.tag_name = self.tag_name.try(:titleize)
	end
end
