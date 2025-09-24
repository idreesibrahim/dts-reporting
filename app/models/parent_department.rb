# == Schema Information
#
# Table name: parent_departments
#
#  id              :bigint           not null, primary key
#  name :string
#  description :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class ParentDepartment < ApplicationRecord
    # associations
    # has_many :departments
    # validations
    validates :name, presence: {message: 'Please enter Name'}, uniqueness: {message: "Name should be unique"}
end
