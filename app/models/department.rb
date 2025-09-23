# == Schema Information
#
# Table name: departments
#
#  id              :bigint           not null, primary key
#  department_name :string
#  department_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Department < ApplicationRecord
	## associations
	# has_many :department_tags
	# has_many :tags, through: :department_tags
	has_and_belongs_to_many :tags, join_table: "department_tags"
	has_and_belongs_to_many :users, join_table: "user_departments"
	belongs_to :parent_department
	## remove extra spaces 
	auto_strip_attributes :department_name, :department_type, squish: true
	## callbacks
	# before_save :titleize_data
	validates :department_name, presence: {message: 'Please Enter Department Name'}, uniqueness: {message: "Department Name should be unique"}
	validates :department_type, presence: {message: 'Please Select Department Type'}
	validates :parent_department_id, presence: {message: 'Please Select Parent Department'}
	# validates :tags, presence: {message: "Please Select tags"}

	# def titleize_data
	# 	self.department_name = self.department_name.try(:titleize)
	# end
	before_save :set_parent_department_name
	def set_parent_department_name
		self.parent_department_name = ParentDepartment.find(self.parent_department_id).name
		self.new_dep_name = self.department_name
	end

end
