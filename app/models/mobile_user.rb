# == Schema Information
#
# Table name: mobile_users
#
#  id              :bigint           not null, primary key
#  username        :string
#  password_digest :string
#  role            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  is_logged_in    :boolean
#  district        :string
#  district_id     :integer
#  uc              :string
#  uc_id           :integer
#  department_id   :integer
#
class MobileUser < ApplicationRecord
	include MobileUserFilterable
	include ActiveModel::Dirty
	include DirtyAssociations
	#serialize :tehsil_ids, Array
	has_secure_password

	## tag categories ["General","Hotspots", "Larvae", "Patient"]
	## many to many relationsship
	# has_many :user_categories
	# has_many :tag_categories, through: :user_categories

	has_and_belongs_to_many :tag_categories, join_table: "user_categories", after_add: :add_user_categories_dirty, before_remove: :delete_user_categories_dirty
	has_and_belongs_to_many :tehsils, join_table: "mobile_user_tehsils", after_add: :add_tehsils_dirty, before_remove: :delete_tehsils_dirty
	has_and_belongs_to_many :ucs, join_table: "mobile_user_ucs", after_add: :add_ucs_dirty, before_remove: :delete_ucs_dirty

	belongs_to :get_district, class_name: "District", primary_key: "id", foreign_key: 'district_id', optional: true
	belongs_to :department, optional: true
	belongs_to :division, optional: true
	has_many :histories
	has_many :dvrs

	has_many :simple_activities, :primary_key => 'id', :foreign_key => "user_id"
	has_many :surveillance_activities
	has_many :patient_activities, :primary_key => 'id', :foreign_key => "user_id"

	validates :username, presence: {message: "User Name can't be blank"}, uniqueness: {message: "User Name should be unique"}
	validates :role, presence:{message: "Please Select Role"}
	validates :department_id, presence:{message: "Please Select Department"}, unless: Proc.new{|user| user.is_dengue_situation_app_user?}
	validates :district_id, presence:{message: "Please Select District"}, unless: Proc.new{|user| user.is_divisional_user?}
	validates :tehsils, presence:{message: "Please Select any Tehsil"}, unless: Proc.new{|user| user.is_dengue_situation_app_user?}
	validates :tag_categories, presence:{message: "Please Select any Tag Category"}, if: Proc.new{|user| user.is_anti_dengue_user?}
	validates :division_id, presence:{message: "Please Select Division"}, if: Proc.new{|user| user.is_divisional_user?}
	validates :cnic, length: {minimum: 13, maximum: 13}, uniqueness: {message: "CNIC should be unique"}, allow_blank: true
	validates :password, presence: true, length: { minimum: 6 }, on: :create
	validates :password, presence: true, length: { minimum: 6 }, if: Proc.new{|user| user.password.present?}
	# NEW VALIDATIONS
	# validates :name, presence: {message: "Name can't be blank"}
	# validates :cnic, presence: {message: "Cnic can't be blank"}, uniqueness: {message: "Cnic should be unique"}
	# validates :contact_no, presence: {message: "Contact number can't be blank"}
	# validates :status, inclusion: { in: [true, false], message: "Status can't be blank" }
	# validates :ucs, presence:{message: "Please Select any Uc"}, unless: Proc.new{|user| user.is_dengue_situation_app_user?}

	# FIlter Scopes

	## default
	scope :district_id, ->(data) { where("mobile_users.district_id = ?", data) }
	scope :username, ->(username_v) { where("lower(mobile_users.username) like ?", "%#{username_v.try(:downcase)}%") }
	scope :role, ->(role_v) { where("mobile_users.role = ?", "#{role_v}") }
	scope :status, ->(data) { where("mobile_users.status is #{data}") }

	scope :filter_by_created_date_from, ->(data) { where("mobile_users.created_at >= ?", data)}
	scope :filter_by_created_date_to, ->(data) { where("mobile_users.created_at <= ?", data)}
	scope :filter_by_updated_date_from, ->(data) { where("mobile_users.updated_at >= ?", data)}
	scope :filter_by_updated_date_to, ->(data) { where("mobile_users.updated_at <= ?", data)}

	## summary of activities user wise report
	scope :is_active, ->{ where(status: true) }
	scope :is_dvr, ->{ where(role: ['DVR(Special Branch)', "DVR(Department User)"]) }
	scope :is_not_tpv, ->{ where("role !=?", 'TPV') }
	scope :is_anti_dengue, ->{where("role =?", "Anti Dengue")}
	scope :is_district_user, ->{ where("role =?", 'District User') }
	scope :is_status_not_null, ->{where("mobile_users.status is not null")}
	scope :filter_by_id, ->(data) { where("mobile_users.id =?", data) }
	scope :filter_by_tehsil_id, ->(data) { joins(:tehsils).where("tehsils.id =?", data) }
	scope :filter_by_tehsil_ids, ->(data) { joins(:tehsils).where("tehsils.id IN(?)", data) }
	scope :filter_by_tehsil, ->(data) { where("tehsils.id =?", data) }
	scope :filter_by_department, ->(data) { where("mobile_users.department_id = ?", data) }
	scope :filter_by_district_id, ->(data) { where("mobile_users.district_id = ?", data) }
	scope :filter_by_username, ->(data) { where("lower(mobile_users.username) like ?", "%#{data.try(:downcase)}%") }
	scope :filter_by_status, ->(data) { where("mobile_users.status is #{data}") }
	scope :filter_by_role, ->(data) { where("mobile_users.role =?", "#{data}") }
	scope :filter_by_sub_department, ->(data) { where("mobile_users.department_id =?", "#{data}") }
	scope :filter_by_parent_department, ->(data) { where("mobile_users.parent_department_id =?", "#{data}") }

	scope :filter_by_active_date_from, ->(data) {data.present? ? where("mobile_users.active_date >= ?", data) : where("true") }
	scope :filter_by_active_date_to, ->(data) {data.present? ? where("mobile_users.active_date <= ?", data) : where("true")}

	scope :filter_by_inactive_date_from, ->(data) {data.present? ? where("mobile_users.inactive_date >= ?", data) : where("true")}
	scope :filter_by_inactive_date_to, ->(data) {data.present? ? where("mobile_users.inactive_date <= ?", data) : where("true")}


	before_save :save_ids
	before_save :save_username_lower
	before_save :update_surveillance_vectory
	before_save :save_parent_department, if: Proc.new{|user| user.department_id.present?}
	before_save :active_inactive_date


	def save_parent_department
		department = Department.find(self.department_id)
		self.dep_name = department.department_name
		if department.present? and department.parent_department.present?
			self.parent_department_name = department.parent_department_name
			self.parent_department_id = department.parent_department_id
		end
		# self.parent_department_name=ParentDepartment.find(self.parent_department_id).name
	end

	def active_inactive_date
		self.active_date = Time.now if (self.status.present? and self.status_changed? and self.status)
		self.inactive_date = Time.now if (self.status.present? || self.status.class == FalseClass) and ( self.status_changed? and !self.status)
	end

	def update_surveillance_vectory
		if tag_category_ids.include?(6)
			self.is_surveillance = true
		else
			self.is_surveillance = false
		end
	end

	def save_username_lower
		self.username = self.username.try(:downcase)
	end
	def save_ids
		(self.district = District.find(district_id).try(:district_name)) rescue nil
	end

	def get_all_tehsil_ids
		tehsils.map(&:id)
	end
	def is_tpv_user?
		role == 'TPV'
	end
	def is_anti_dengue_user?
		role == 'Anti Dengue'
	end
	def is_district_user?
		role == 'DsApp District User'
	end
	def is_divisional_user?
		role == 'DsApp Divisional User'
	end

	def is_dvr_special_branch?
		role == 'DVR(Special Branch)'
	end
	def is_dvr_department_user?
		role == 'DVR(Department User)'
	end

	def is_dengue_situation_app_user?
		is_district_user? || is_divisional_user?
	end
	def is_dvr_role?
		is_dvr_special_branch? || is_dvr_department_user?
	end

	def reload(id)
		api_user = MobileUser.find_by_id(id)
		user_resp = Hash.new
		u_towns = []
	if api_user.present?
		user_resp["user_id"] = api_user.id
		user_resp["username"] = api_user.username
    	user_resp["name"] = api_user.name
    	user_resp["cnic"] = api_user.cnic
    	user_resp["contact_no"] = api_user.contact_no
		user_resp["role"] = api_user.role
    	user_resp["is_forgot"] = api_user.is_forgot
    	user_resp["is_prof_update"] = api_user.is_prof_update
    	user_resp["is_surveillance"] = api_user.is_surveillance
    	user_resp["manage_hotspot"] = api_user.manage_hotspot
		user_resp["active"] = api_user.status
		api_user.tehsils.each do |tehsil|
      	u_towns << { "town_id": tehsil.id, "town": tehsil.tehsil_name}
    end
		user_resp["towns"] =  u_towns
		user_resp["district_id"] = api_user.district_id
		user_resp["district"] = api_user.district
		user_resp["uc_id"] = Uc.first.id
		user_resp["uc"] = Uc.first.uc_name
		user_resp["department_id"] = api_user.department_id
		user_resp["department"] = api_user.department.try(:department_name)
	else
	end
		return user_resp
	end

	# -----------------------------------------------------------------------------------
  after_create :write_history
	before_update :update_history, if: Proc.new{|user| user.update_user_id}
  private
  def write_history
		audited_changes = self.as_json

		## HABTM Relationship
		audited_changes["tehsils"] = self._new_tehsils.try(:join, ',') if self._new_tehsils.present?
		audited_changes["tag_categories"] = self._new_user_categories.try(:join, ',') if self._new_user_categories.present?
		audited_changes["ucs"] = self._new_ucs.try(:join, ',') if self._new_ucs.present?

		audited_changes["district_id"] = self.get_district.district_name.to_s if self.get_district.present?
		audited_changes["department_id"] = self.department.department_name.to_s if self.department.present?

    History.create!(mobile_user_id: self.id, audited_changes: audited_changes, user_id: self.update_user_id, action: "create")
  end
	def update_history
    audited_changes = {}

		self.changes.each do |attribute_name, values|
			if ['updated_at', "password_digest"].exclude?(attribute_name)
				before_value = values[0].to_s.truncate(700) if !values[0].nil?
				after_value = values[1].to_s.truncate(700) if !values[1].nil?

				if attribute_name == 'district_id'
					before_value = District.find(before_value).try(:district_name) if before_value.present?
					after_value = District.find(after_value).try(:district_name) if after_value.present?
				end

				if attribute_name == 'department_id'
					before_value = Department.find(before_value).try(:department_name) if before_value.present?
					after_value = Department.find(after_value).try(:department_name) if after_value.present?
				end

				audited_changes["#{attribute_name}"] = ["#{before_value}", "#{after_value}"]
			end
    end
		if audited_changes.present?
			user_id = self.update_user_id
			# self._old_ucs = (self.ucs.present? ? self.ucs.map(&:uc_name) : "") unless self._old_ucs.present?

			## HABTM Relationship
			if is_user_categories?
				self._old_user_categories = (self.tag_categories.present? ? self.tag_categories.map(&:category_name) : "") unless self._old_user_categories.present?
				self._new_user_categories = (self.tag_categories.present? ? self.tag_categories.map(&:category_name) : "") unless self._new_user_categories.present?
				audited_changes["tag_categories"] = ["#{self._old_user_categories.try(:join, ',')}", "#{self._new_user_categories.try(:join, ',')}"]
			end

			if is_tehsil_changes?
				self._old_tehsils = (self.tehsils.present? ? self.tehsils.map(&:tehsil_name) : "") unless self._old_tehsils.present?
				self._new_tehsils = (self.tehsils.present? ? self.tehsils.map(&:tehsil_name) : "") unless self._new_tehsils.present?
				audited_changes["tehsils"] = ["#{self._old_tehsils.try(:join, ',')}", "#{self._new_tehsils.try(:join, ',')}"]
			end

			if is_uc_changes?
				self._old_ucs = (self.ucs.present? ? self.ucs.map(&:uc_name) : "") unless self._old_ucs.present?
				self._new_ucs = (self.ucs.present? ? self.ucs.map(&:uc_name) : "") unless self._new_ucs.present?
				audited_changes["ucs"] = ["#{self._old_ucs.try(:join, ',')}", "#{self._new_ucs.try(:join, ',')}"]
			end

			History.create!(mobile_user_id: self.id, audited_changes: audited_changes, user_id: user_id, action: "update")
		else
			if is_many_to_many_relation_changed?
				user_id = self.update_user_id

				## HABTM Relationship
				if is_user_categories?
					self._old_user_categories = (self.tag_categories.present? ? self.tag_categories.map(&:category_name) : "") unless self._old_user_categories.present?
					self._new_user_categories = (self.tag_categories.present? ? self.tag_categories.map(&:category_name) : "") unless self._new_user_categories.present?
					audited_changes["tag_categories"] = ["#{self._old_user_categories.try(:join, ',')}", "#{self._new_user_categories.try(:join, ',')}"]
				end

				if is_tehsil_changes?
					self._old_tehsils = (self.tehsils.present? ? self.tehsils.map(&:tehsil_name) : "") unless self._old_tehsils.present?
					self._new_tehsils = (self.tehsils.present? ? self.tehsils.map(&:tehsil_name) : "") unless self._new_tehsils.present?
					audited_changes["tehsils"] = ["#{self._old_tehsils.try(:join, ',')}", "#{self._new_tehsils.try(:join, ',')}"]
				end

				if is_uc_changes?
					self._old_ucs = (self.ucs.present? ? self.ucs.map(&:uc_name) : "") unless self._old_ucs.present?
					self._new_ucs = (self.ucs.present? ? self.ucs.map(&:uc_name) : "") unless self._new_ucs.present?
					audited_changes["ucs"] = ["#{self._old_ucs.try(:join, ',')}", "#{self._new_ucs.try(:join, ',')}"]
				end

				History.create!(mobile_user_id: self.id, audited_changes: audited_changes, user_id: user_id, action: "update")
			end
		end
  end
	def is_tehsil_changes?
		self._old_tehsils.present? || self._new_tehsils.present?
	end
	def is_user_categories?
		self._old_user_categories.present? || self._new_user_categories.present?
	end
	def is_uc_changes?
		self._old_ucs.present? || self._new_ucs.present?
	end
	def is_many_to_many_relation_changed?
		is_tehsil_changes? || is_user_categories? || is_uc_changes?
	end

 end
