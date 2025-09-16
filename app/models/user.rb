class User < ApplicationRecord
	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
	devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :trackable, :timeoutable, :lockable
	include UserFilterable
	## enums
	enum :role, %w(admin
				hospital_user 
				lab_user
				district_user
				department_user
				dpc_user
				patient_department_user
				provisional_incharge
				hospital_supervisor
				lab_supervisor
				tehsil_user
				epc_user
				phc_user
				user_registration
				master_user
				pitb_admin
				ceo)

	## associations
	belongs_to :district, optional: true
	belongs_to :tehsil, optional: true
	belongs_to :hospital, optional: true
	belongs_to :department, optional: true


	# belongs_to :lab, optional: true
	
	## merge lab to hospitals relations
	belongs_to :lab, class_name: "Hospital", primary_key: "id", foreign_key: 'lab_id', optional: true

	## Hospital Info/Insecticide
	has_many :medicine_stocks
	has_many :ppe_stocks
	has_many :pcr_machines
	has_many :insecticide_stocks
  
	enum :department_type, %w(Allied DCO)
	has_and_belongs_to_many :departments, join_table: "user_departments"
	
	## scopes
	scope :filter_by_username, ->(data){where("users.username ILIKE(?)", "%#{data.downcase}%")}
	scope :filter_by_role, ->(data){where("users.role =?", User.roles[data])}
	scope :filter_by_department, ->(data){where("users.department_id =?", data)}

	# NEW SCOPES
	scope :filter_by_id, ->(data){where("users.id =?", data)}
	scope :filter_by_district, ->(data){where("users.district_id =?", data)}
	scope :filter_by_tehsil, ->(data){where("users.tehsil_id =?", data)}

## validates
	validates :username, presence: {message: "Username can't be blank"}, uniqueness: {message: "Username has already been taken"}
	validates :role, presence: {message: "Role can't be blank"}
	validates :district_id, presence: {message: "District can't be blank"}, if: Proc.new{|user| user.is_district_wise_users?}
	validates :tehsil_id, presence: {message: "Tehsil can't be blank"}, if: Proc.new{|user| user.is_tehsil_wise_user?}
	validates :hospital_id, presence: {message: "Hospital can't be blank"}, if: Proc.new{|user| user.is_hospital_wise_users?}
	validates :cnic, presence: {message: "Cnic can't be blank"}, uniqueness: {message: "Cnic has already been taken"}, if: Proc.new{|user| user.is_pitb_admin?}
	
	validates :department_id, presence: {message: "Department can't be blank"}, if: Proc.new{|user| user.is_department_wise_user?}
	
	validates :department_type, presence:{message: "Please Select any Department Type"}, if: Proc.new{|user| user.is_user_registration?}
	validates :departments, presence:{message: "Please Select any Department"}, if: Proc.new{|user| user.is_user_registration?}

	validates :lab_id, presence: {message: "Lab can't be blank"}, if: Proc.new{|user| user.is_lab_patient_users?}
	
	validates :is_third_party_audit, inclusion: { in: [ true, false ], :message => "Please Select Third Party Audit" }, if: Proc.new{|user| user.provisional_incharge?}

	scope :filter_by_status, ->(data){where("users.status =?", data)}
	scope :death_notification_users, -> {
		where(role: [
		User.roles[:admin],
		User.roles[:pitb_admin],
		User.roles[:provisional_incharge],
		User.roles[:district_user]
		])
	}
  
	def get_hospitals_role_wise
		if admin?
			Hospital.order("hospital_name").collect { | hospital | [hospital.hospital_name, hospital.id] }
		elsif hospital_user? or hospital_supervisor?
			[[hospital.hospital_name, hospital.id]]
		else
			Hospital.order("hospital_name").collect { | hospital | [hospital.hospital_name, hospital.id] }
		end
	end
	def email_required?
	  false
	end
	def email_changed?
		false
	end
	def is_hospital_wise_users?
		hospital_user?
	end

	def is_department_wise_user?
		department_user?
	end
	def is_lab_patient_users?
		lab_user?
	end
	def is_district_wise_users?
		hospital_user? || lab_user? || district_user? || ceo?
	end
	def is_tehsil_wise_user?
		tehsil_user?
		end
	def send_reset_password_instructions
		return false if admnin?
		super
	end
	def default_hospital_user?
		hospital_user?
	end
	def is_dpc_user?
			dpc_user?
	end
	def is_user_registration?
		user_registration?
	end
	def can_manage_hotspot?
		hotspot_status?
	end
	def is_pitb_admin?
		pitb_admin?
  	end

	def active_for_authentication?
		super && self.status
	end

	def inactive_message
		"Sorry, this account has been deactivated."
	end
	def valid_generate_tpv?
			provisional_incharge? and is_third_party_audit?
	end
		def is_deag_review_status_enable?
			admin? || hospital_user? || provisional_incharge? || hospital_supervisor?
		end
		def is_district_or_tehsil_user?
			district_user? || tehsil_user?
		end
	private

	def validate_password_fields
		errors.add(:base, "Please enter correct values") if password.blank? || password_confirmation.blank? || (password != password_confirmation)
	end
end
