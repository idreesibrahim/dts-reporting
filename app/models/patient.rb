class Patient < ApplicationRecord
	include PatientFilterable

	# audited
	# has_many :projects, dependent: :destroy
	# has_associated_audits

	## history save
	audited except: [
		:residence_count,
		:is_residence_household,
		:permanent_count,
		:is_permanent_household,
		:workplace_count,
		:is_workplace_household,
		:residence_tagged,
		:residence_lat,
		:residence_long,
		:workplace_tagged,
		:workplace_lat,
		:workplace_long,
		:permanent_residence_tagged,
		:permanent_lat,
		:permanent_long
	  ]
	## soft delete
	acts_as_paranoid
	## associations
	has_many :activities, class_name: 'PatientActivity'
	has_many :test_logs
	has_one :lab_result, :dependent => :destroy
	has_associated_audits
	accepts_nested_attributes_for :lab_result
  has_many :notifications, :as => :notifiable

	belongs_to :user, optional: true
	belongs_to :lab_patient, optional: true
	belongs_to :province, optional: true
	has_one :patient_transfer
	has_many :patient_transfer_expps

	belongs_to :admitted_hospital, class_name: 'Hospital', primary_key: "id", foreign_key: 'hospital_id', optional: true

	belongs_to :g_district, class_name: "District", primary_key: "id", foreign_key: 'district_id', optional: true
	belongs_to :g_perm_district, class_name: "District", primary_key: "id", foreign_key: 'permanent_district_id', optional: true
	belongs_to :g_workplc_district, class_name: "District", primary_key: "id", foreign_key: 'workplace_district_id', optional: true

	belongs_to :g_perm_uc, class_name: "Uc", primary_key: "id", foreign_key: 'permanent_uc_id', optional: true

	belongs_to :change_by_request, class_name: "User", primary_key: "id", foreign_key: 'request_user_id', optional: true
	belongs_to :updated_by, class_name: "User", primary_key: "id", foreign_key: 'updated_id', optional: true
	belongs_to :from_lab, class_name: "User", primary_key: "id", foreign_key: 'lab_user_id', optional: true
	belongs_to :from_hospital, class_name: "User", primary_key: "id", foreign_key: 'user_id', optional: true
	belongs_to :confirmation_by, class_name: "User", primary_key: "id", foreign_key: 'confirmation_id', optional: true
	belongs_to :death_verify_by, class_name: "User", primary_key: "id", foreign_key: 'death_verify_id', optional: true
	belongs_to :death_verify_non_dengue_by, class_name: "User", primary_key: "id", foreign_key: 'death_verify_non_dengue_id', optional: true

	enum :provisional_diagnosis, { "Non-Dengue": 0, "Probable": 1, "Suspected": 2, "Confirmed": 3}
	enum :patient_status, { "Closed": 0, "In Process": 1, "Lab": 2}
	enum :entered_by, { "By Hospital": 0, "By Lab": 1}
	enum :confirmation_role, { "Confirmed by Hospital": 0, "Confirmed by Lab": 1}
	enum :patient_outcome, { "Admitted": 0, "Death": 1, "Discharged": 2, "LAMA": 3, "Outpatient": 4}
	enum :patient_condition, { "Critical": 0, "Stable": 1}
	enum :transfer_type, { "Not Transferred": 0, "Lab To Hospital": 1, 'DPC': 2}
	enum :expp_transfer_type, { "Outside Punjab": 0, "Outside Pakistan": 1}
	enum :p_search_type, { "CNIC": 0, "Passport": 1 }
	enum :attachment_reason, { "Request from DGHS": 0, "Test Entry": 1 }
	enum :transferred_status, [:pending, :initiated, :approved, :rejected]


	## scopes
	scope :ascending, ->{order("patients.created_at DESC")}
	scope :last_48_confirmation_date, ->{where("patients.confirmation_date >=?", 48.hours.ago.beginning_of_day)}
	scope :confirmed_patients, ->{where("patients.provisional_diagnosis =?", 3)}
	#	<<<< Ability CanCan >>>
	scope :cannot_edit, -> {where("patients.patient_outcome =?", 'Death')}
	scope :in_process_status, -> {where("patients.patient_status =?", 'In Process')}
	scope :not_in_process_status, -> {where("patients.patient_status !=?", 'Closed')}
	## 	<<< End Ability Cancan >>>
	scope :get_patient_activities_prov_diag, ->{where(provisional_diagnosis: ["Probable", "Suspected", "Confirmed"])}
	scope :get_patient_activities_non_dengue, ->{where("provisional_diagnosis !=?", 0)}
	scope :unreleased, -> {where("patients.is_released is not true")}
	scope :released, -> {where("patients.is_released is true")}
	scope :filter_by_cnic, ->(data){where("cnic =?", data)}
	scope :filter_by_patient_contact, ->(data){where("patient_contact =?", data)}

	scope :filter_by_passport, ->(data){where("passport =?", data.try(:downcase))}
	scope :is_beds_patients, ->{ unreleased.where(patient_outcome: 'Admitted').where("patients.entry_source is null or patients.entry_source =?", nil).where(patient_status: "In Process")}
	scope :filter_by_patient_name, ->(data){where("lower(patient_name) like ?", "%#{data.try(:downcase)}%")}
	scope :filter_by_tehsil_id, ->(data){data.present? ? (where("tehsil_id =?", data)) : where("true")}
	scope :filter_by_tehsil_ids, ->(data){data.present? ? (where("tehsil_id IN(?)", data)) : where("true")}

	## Match by Labs Apis Patient Name and Contact as Uniq

	scope :is_uniq_p_name, ->(data){data.present? ? (where("TRIM(lower(patient_name)) =?", data.try(:downcase).try(:strip))) : where("true")}
	scope :is_uniq_p_contact, ->(data){data.present? ? (where("replace(patient_contact, '-', '') =?", data.try(:scan, /\d/).try(:join))) : where("true") }

	scope :filter_by_province_id, ->(data){data.present? ? (where("patients.province_id =?", data) ) : where("true")}
	scope :filter_by_district_id, ->(data){data.present? ? (where("patients.district_id =?", data) ) : where("true")}
	scope :filter_by_hospital_id, ->(data){data.present? ? (where("patients.hospital_id =?", data) ) : where("true")}
	scope :filter_by_outcome, ->(data){where("patient_outcome =?", Patient.patient_outcomes[data])}
	scope :filter_by_condition, ->(data){where("patient_condition =?", Patient.patient_conditions[data])}
	scope :filter_by_patient_status, ->(data){where("patient_status =?", Patient.patient_statuses[data])}
	scope :filter_by_prov_diagnosis, ->(data){where("patients.provisional_diagnosis =?", Patient.provisional_diagnoses[data])}

	scope :filter_by_confirm_by, ->(data){where("confirmation_role =?", Patient.confirmation_roles[data])}

	scope :filter_by_uc_id, ->(data){data.present? ? (where("uc_id =?", data) ) : where("true")}
	scope :filter_by_p_id, ->(data){where("patients.id =?", data)}
	scope :filter_by_month, ->(data){data.present? ? (where("extract(month from patients.created_at) = ?", data) ) : where("true")}
	scope :filter_by_year, ->(data){data.present? ? (where("extract(year from patients.created_at) = ?", data) ) : where("true")}
	scope :filter_by_confirmation_month, ->(data){data.present? ? (where("extract(month from patients.confirmation_date) = ?", data) ) : where("true")}
	scope :filter_by_confirmation_year, ->(data){data.present? ? (where("extract(year from patients.confirmation_date) = ?", data) ) : where("true")}
	scope :filter_by_d_from, ->(data){data.present? ? (where("patients.created_at::DATE >= ?", Time.parse("#{data}").to_date) ) : where("true")}
	scope :filter_by_d_to, ->(data){data.present? ? (where("patients.created_at::DATE <= ?", Time.parse("#{data}").to_date) ) : where("true")}

	scope :filter_by_datefrom, ->(data){data.present? ? (where("patients.created_at >= ?", data) ) : where("true")}
	scope :filter_by_dateto, ->(data){data.present? ? (where("patients.created_at <= ?", data) ) : where("true")}

	# scope :filter_by_confirm_datefrom, ->(data){data.present? ? (where("patients.confirmation_date >= ?", data) ) : where("true")}
	# scope :filter_by_confirm_dateto, ->(data){data.present? ? (where("patients.confirmation_date <= ?", data) ) : where("true")}

	scope :filter_by_confirmation_date_from, -> (data){data.present? ? (where("TO_CHAR(patients.confirmation_date, 'YYYY-MM-DD THH24:MI') >= ?", data.insert(10, ' ')) ) : where("true")}
	scope :filter_by_confirmation_date_to, -> (data){data.present? ? (where("TO_CHAR(patients.confirmation_date, 'YYYY-MM-DD THH24:MI') <= ?", data.insert(10, ' ')) ) : where("true")}

	scope :filter_by_confirm_datefrom, ->(data){where("true")}
	scope :filter_by_confirm_dateto, ->(data){where("true")}

	## Deag Reviewed
	scope :filter_by_deag_reviewed, ->(data){where(deag_reviewed_options(data))}

	scope :filter_by_from, ->(data){data.present? ? (where("patients.created_at::DATE >=?", Time.parse("#{data}").to_date) ) : where("true")}
	scope :filter_by_to, ->(data){data.present? ? (where("patients.created_at::DATE <=?", Time.parse("#{data}").to_date) ) : where("true")}
	scope :filter_by_facility_type, ->(data){data.present? ? (joins(:admitted_hospital).where("hospitals.facility_type = ?", data)) : where("true")}
	scope :filter_by_hospital_category, ->(data){data.present? ? (joins(:admitted_hospital).where("hospitals.category = ?", data)) : where("true")}

	scope :phc_patients_joins, ->{includes(:lab_patient, :lab_result, :from_lab, :user, admitted_hospital: :district)}
	## scopes
	scope :get_tehsils, ->(tehsils){where("patients.tehsil_id IN(?)", tehsils)}
	## RESIDENCE
	scope :is_residence_tagged, -> { where("patients.residence_tagged is true") }
	scope :is_residence_untagged, -> { where("patients.residence_tagged is false") }
	## WORKPRELACE
	scope :get_workplace_tehsil, ->(tehsils){where("patients.workplace_tehsil_id IN(?)", tehsils)}
	scope :is_workplace_tagged, ->{where("patients.workplace_tagged is true")}
	scope :is_workplace_untagged, ->{where("patients.workplace_tagged is false")}
	## PERMAANEN TEHSIL ID
	scope :get_permanent_tehsil, ->(tehsils){where("patients.permanent_tehsil_id IN(?)", tehsils)}
	scope :is_permanent_residence_tagged, ->{where("patients.permanent_residence_tagged is true")}
	scope :is_permanent_residence_untagged, ->{where("patients.permanent_residence_tagged is false")}
	## Patient Data Api Mobile
	scope :select_patient_data, ->{select("id, patient_name, cnic, cnic_relation, patient_contact, relation_contact, provisional_diagnosis, address, uc, uc_id, tehsil, tehsil_id, workplace_address, workplace_uc, workplace_uc_id, workplace_tehsil, workplace_tehsil_id, permanent_address, permanent_uc, permanent_uc_id, permanent_tehsil, permanent_tehsil_id, residence_count, workplace_count, permanent_count, permanent_residence_tagged, workplace_tagged, residence_tagged, residence_lat, residence_long, workplace_lat, workplace_long, permanent_lat, permanent_long, radius, confirmation_date").where("created_at::date > '2021-12-31'")}
  scope :untagged_patient_data_where,->(data){where("(tehsil_id IN(?) and (residence_tagged is not true)) OR (workplace_tehsil_id IN(?) and (workplace_tagged is not true)) OR (permanent_tehsil_id IN(?) and (permanent_residence_tagged is not true))", data, data, data)}

	## Un Tagged Patients
	scope :untagged_residence_tagged, ->(data){where("residence_tagged is not true and tehsil_id #{inOrEqualQuery(data)}", data)}
	scope :untagged_workplace_tagged, ->(data){where("workplace_tagged is not true and workplace_tehsil_id #{inOrEqualQuery(data)}", data)}
	scope :untagged_permanent_residence_tagged, ->(data){where("permanent_residence_tagged is not true and permanent_tehsil_id #{inOrEqualQuery(data)}", data)}

	## Tagged patients
	scope :tagged_residence_tagged, ->(data){where("residence_tagged is true and tehsil_id #{inOrEqualQuery(data)}", data)}
	scope :tagged_workplace_tagged, ->(data){where("workplace_tagged is true and workplace_tehsil_id #{inOrEqualQuery(data)}", data)}
	scope :tagged_permanent_residence_tagged, ->(data){where("permanent_residence_tagged is true and permanent_tehsil_id #{inOrEqualQuery(data)}", data)}

	## Polygons Map

	scope :get_patient_activities, ->(patient_tag_id, date_filter, district_id){select("patients.id as patient_id, patients.patient_name as patient_name, pa.latitude, pa.longitude, pa.patient_place, pa.provisional_diagnosis, pa.tag_name, patients.district as district, patients.tehsil as tehsil_name, patients.uc as uc_name, patients.residence_count as residence_count").joins("INNER JOIN patient_activities pa ON pa.patient_id = patients.id and pa.patient_place = 2 and pa.tag_id = '#{patient_tag_id}' and #{date_filter}").where("patients.provisional_diagnosis = '3' AND pa.district_id = '#{district_id}'")}

	scope :get_patient_activities_tehsil, ->(patient_tag_id, date_filter, district_id, tehsil_id){select("patients.id as patient_id, patients.patient_name as patient_name, pa.latitude, pa.longitude, pa.patient_place, pa.provisional_diagnosis, pa.tag_name, patients.district as district, patients.tehsil as tehsil_name, patients.uc as uc_name, patients.residence_count as residence_count").joins("INNER JOIN patient_activities pa ON pa.patient_id = patients.id and pa.patient_place = 2 and pa.tag_id = '#{patient_tag_id}' and #{date_filter}").where("patients.provisional_diagnosis = '3' AND pa.district_id = '#{district_id}' AND pa.tehsil_id = '#{tehsil_id}'")}
  
	scope :is_confirmed_patient, ->{where("patients.provisional_diagnosis = ?", provisional_diagnoses[:Confirmed])}
	scope :exclude_islamabad, ->{where("patients.district_id !=?", 12)}
	scope :last_24_hr, ->{where("patients.created_at > ?", 24.hours.ago)}
	scope :verified_deaths, -> {
		where("patients.patient_outcome = ? and patients.death_verify is true", patient_outcomes[:Death])
	}
	scope :unverified_deaths, -> {
		where("patients.patient_outcome = ? and patients.death_verify is not true", patient_outcomes[:Death])
	}

	scope :get_death_patient, ->(patient_tag_id, date_filter, district_id){select("patients.id as patient_id, patients.patient_name as patient_name, pa.latitude, pa.longitude, pa.patient_place, pa.provisional_diagnosis, pa.tag_name, patients.district as district, patients.tehsil as tehsil_name, patients.uc as uc_name, patients.death_date as death_date").joins("INNER JOIN patient_activities pa ON pa.patient_id = patients.id and pa.patient_place = 2 and pa.tag_id = '#{patient_tag_id}' and #{date_filter}").where("patients.provisional_diagnosis = '3' and patients.patient_outcome = '1' and patients.death_verify is true and pa.district_id = '#{district_id}'")}

	scope :get_death_patient_tehsil, ->(patient_tag_id, date_filter, district_id, tehsil_id){select("patients.id as patient_id, patients.patient_name as patient_name, pa.latitude, pa.longitude, pa.patient_place, pa.provisional_diagnosis, pa.tag_name, patients.district as district, patients.tehsil as tehsil_name, patients.uc as uc_name, patients.death_date as death_date").joins("INNER JOIN patient_activities pa ON pa.patient_id = patients.id and pa.patient_place = 2 and pa.tag_id = '#{patient_tag_id}' and #{date_filter}").where("patients.provisional_diagnosis = '3' and patients.patient_outcome = '1' and patients.death_verify is true and pa.district_id = '#{district_id}' AND pa.tehsil_id = '#{tehsil_id}'")}

	#   Diagnosis filter

	# scope :filter_by_diagnosis, -> (data) { data.present? ? (joins(:lab_result).where("lab_results.diagnosis = ?", data)) : where("true") }

	# scope :filter_by_diagnosis, -> (data) { data.present? ? (where("lab_results.diagnosis = ?", data)) : where("true") }

	scope :filter_by_diagnosis, -> (data) { data.present? ? (includes(:lab_result).where(lab_results: { diagnosis: data })) : where("true")}
	scope :filter_by_travel_history, ->(data){data.present? ? (where("patients.travel_history_added =?", data) ) : where("true")}

	def self.inOrEqualQuery(data)
		data.size > 1 ? "IN(?)" : "=?"
	end

	validates_associated :lab_result, :message => "Lab's Section is invalid", on: :update # validates_associated is added for lab validations

	#Validations
	validates :hospital_id, presence: {message: 'Please select hospital'}
	validates :patient_name, presence: {message: 'Please enter patient name'}
	validates :fh_name, presence: {message: "Please enter guardian's name"}
	# validates :age, presence: {message: "Please enter age"}
	# validates :age_month, presence: {message: "Please enter age in months"}, if: Proc.new{|obj| obj.age == 0}
	validates :age, presence: { message: "Please enter age" },
	numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 999, message: "Age must be a number with up to 3 digits" }

	validates :age_month, presence: { message: "Please enter age in months" },
				numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 11, message: "Age in months must be between 1 and 11" },
				if: Proc.new { |obj| obj.age == 0 }


	validates :gender, presence: {message: 'Please select gender'}
	# validates :relation, presence: {message: 'Please select relation'}
	validates :cnic, presence: {message: 'Please enter CNIC'}, format: { with: /(^[0-9]{5}-[0-9]{7}-[0-9]$)/, message: 'Please Enter Correct Format of CNIC'}, if: Proc.new{|obj| obj.p_search_type == 'CNIC'}
	validates :passport, presence: {message: 'Please enter Passport'}, length: {minimum: 9, maximum: 9, message: 'Passport Length should be 9 characters'}, if: Proc.new{|obj| obj.p_search_type == 'Passport'}
	# validates :country, presence: {message: 'Please select country'},if: Proc.new{|obj| obj.p_search_type == 'Passport'}
	# validates :cnic_relation, presence: {message: "Please enter Guardian's Relation"}
	validates :patient_contact, presence: {message: "Please enter patient's contact number"}
	# validates :relation_contact, presence: {message: "Please enter guardian's contact number"}

	validates :address, presence: {message: "Please enter patient's address"}
	validates :district_id, presence: {message: "Please enter patient's district"}
	validates :tehsil_id, presence: {message: "Please enter patient's tehsil"}
	# validates :uc_id, presence: {message: "Please enter patient's union council"}

	validates :permanent_address, presence: {message: "Please enter permanent address"}
	validates :permanent_district_id, presence: {message: "Please enter permanent district"}
	validates :permanent_tehsil_id, presence: {message: "Please enter permanent tehsil"}
	# validates :permanent_uc_id, presence: {message: "Please enter permanent union council"}
	validates :reporting_date, presence: {message: "Please enter Reporting Date"}

	# validates :workplace_address, presence: {message: "Please enter workplace address"}
	# validates :workplace_district_id, presence: {message: "Please enter workplace district"}
	# validates :workplace_tehsil_id, presence: {message: "Please enter workplace tehsil"}
	# validates :workplace_uc_id, presence: {message: "Please enter workplace union council"}

	# validates :fever, presence: {message: "Please select fever ( > 2 and < 10 days duration)"}

	validates :previous_dengue_fever, inclusion: {in: [true, false], message: "Please select previous H/O dengue fever"}, if: Proc.new{|obj| is_hospital_user?(obj) }
	validates :associated_symptom, inclusion: {in: [true, false], message: "Please select associated symptom"}, if: Proc.new{|obj| is_hospital_user?(obj) }
	validates :provisional_diagnosis, presence: {message: "Please select provisional diagnosis"}

	# validates :patient_status, presence: {message: "Please select patient status"}
	validates :patient_outcome, presence: {message: "Please select patient outcome"}, if: Proc.new{|obj| is_hospital_user?(obj)}
	# validates :patient_condition, presence: {message: "Please select patient condition"}
	validates :comments, presence: {message: "Please enter comments"}
	validates :death_date, presence: {message: "Please enter death date"}, if: Proc.new{|obj| obj.patient_outcome == "Death"}

	validate :lab_result_hospital_wise_user, if: Proc.new{|obj| is_hospital_user?(obj)}
	validate :lab_result_lab_wise_user, if: Proc.new{|obj| is_lab_user?(obj)}
	validate :patient_name_and_contact_should_unique, if: Proc.new{|obj| (obj.patient_name.present? and obj.patient_contact.present?)}

	## Attachments
	mount_uploader :attachment, PatientUploader
	validates :attachment_reason, presence: {message: "Please select Reason"}, if: Proc.new { |obj| obj.is_master_user? }
	validates :attachment, presence: {message: "Please select Attachment"}, if: Proc.new { |obj| obj.is_master_user? }

  validate :attachment_size, if: :is_master_user?
	validates :workplace_address, presence: {message: "Please enter workplace address"}, on: :create

	## Patient Transfers Internally

	before_update :patient_transfer_internally, if: -> { is_master_user? and provisional_diagnosis == "Confirmed" and self.district_id_was != self.district_id}

	def patient_transfer_internally
		begin
			## outside punjab
			if self.expp_transfer_type == 'Outside Punjab'
				self.outside_punjab = self.outside_punjab + 1
				from_province_name = Province.find(self.province_id_was).try(:province_name) if self.province_id_was.present?
				to_province_name = Province.find(self.province_id).try(:province_name) if self.province_id.present?
				patient_transfer_expp= {
					patient_id: self.id,
					cnic: self.cnic,
					transfer_type: 0,
					from_province_id: self.province_id_was,
					to_province_id: self.province_id,
					from_province_name: from_province_name,
					to_province_name: to_province_name,
					from_district_id: self.district_id_was,
					to_district_id: self.district_id,
					from_district_name: self.district_was,
					to_district_name: self.district,
					from_tehsil_id: self.tehsil_id_was,
					to_tehsil_id: self.tehsil_id,
					from_tehsil_name: self.tehsil_was,
					to_tehsil_name: self.tehsil,
					from_hospital_id: self.hospital_id_was,
					to_hospital_id: self.hospital_id,
					from_hospital_name: self.hospital_was,
					to_hospital_name: self.hospital,
					confirmation_at: self.confirmation_date,
					user_id: self.change_by_request.id,
					username: self.change_by_request.username
				}
				PatientTransferExpp.create(patient_transfer_expp)
			end

			## outside country
			if self.expp_transfer_type == 'Outside Pakistan'
				self.outside_pakistan = self.outside_pakistan + 1

				from_province_name = Province.find(self.province_id_was).try(:province_name) if self.province_id_was.present?
				to_province_name = Province.find(self.province_id).try(:province_name) if self.province_id.present?
				patient_transfer_expp= {
					patient_id: self.id,
					cnic: self.cnic,
					transfer_type: 1,
					from_province_id: self.province_id_was,
					to_province_id: self.province_id,
					from_province_name: from_province_name,
					to_province_name: to_province_name,
					from_district_id: self.district_id_was,
					to_district_id: self.district_id,
					from_district_name: self.district_was,
					to_district_name: self.district,
					from_tehsil_id: self.tehsil_id_was,
					to_tehsil_id: self.tehsil_id,
					from_tehsil_name: self.tehsil_was,
					to_tehsil_name: self.tehsil,
					from_hospital_id: self.hospital_id_was,
					to_hospital_id: self.hospital_id,
					from_hospital_name: self.hospital_was,
					to_hospital_name: self.hospital,
					confirmation_at: self.confirmation_date,
					user_id: self.change_by_request.id,
					username: self.change_by_request.username
				}
				PatientTransferExpp.create(patient_transfer_expp)
			end
		end
	end


	# New Patient validations

	validates :admission_date, presence: { message: "As Patient outcome is admitted, so please select admission date" }, if: Proc.new { |obj| obj.patient_outcome == 'Admitted' and check_users?(obj)}

	validates :discharge_date, presence: { message: "As Patient outcome is discharged, so please select discharge date."}, if: Proc.new { |obj| obj.patient_outcome == 'Discharged' and check_users?(obj)}

	validate :discharge_date_not_less_than_admission_date, if: Proc.new { |obj| obj.admission_date.present? and obj.discharge_date.present? and check_users?(obj)}

	#   No probable to suspected
	validate :outcome_from_probable_to_suspected, if: Proc.new{|obj| (obj.provisional_diagnosis_was == 'Probable' and obj.provisional_diagnosis == 'Suspected') }, on: :update

	# New Validation for R-5.5.2
	validates :date_of_onset, presence: {message: "Please select date of onset fever"}, if: -> {change_by_request.hospital_user?}, on: :create

	def check_users?(obj)
		(obj.change_by_request.present? and ( obj.change_by_request.hospital_user? || obj.change_by_request.epc_user? || obj.change_by_request.master_user? || obj.change_by_request.admin?  ) )
	end

	def discharge_date_not_less_than_admission_date
		return errors.add(:base, "Discharged date should always be greater than or equal to Admission date.") if self.discharge_date < self.admission_date
	end

  def outcome_from_probable_to_suspected
	  return errors.add(:base, "You cannot change provisional diagnosis from probable to suspected.") unless is_master_user?
  end

  def is_master_user?
		(change_by_request.present? and change_by_request.master_user?)
	end

  def attachment_size
    return unless attachment.present? && attachment.size > 1.megabyte
    errors.add(:attachment, "Attachment size should be less than 1MB")
  end

	before_save :patient_provisional_diagnosis
	def patient_provisional_diagnosis
		if is_valid_confirmed_record?(provisional_diagnosis_was)
			self.provisional_diagnosis = 'Confirmed'
			self.other_diagnosed_fever = self.other_diagnosed_fever_was
			self.patient_outcome = self.patient_outcome_was
		end
	end
	def is_valid_confirmed_record?(params_provisional_diagnosis)
		# puts "=====================old = #{params_provisional_diagnosis}"
		# puts "=====================New = #{self.provisional_diagnosis}"
		(
			params_provisional_diagnosis.present? and
		 (self.provisional_diagnosis != params_provisional_diagnosis and self.provisional_diagnosis == 'Confirmed' and params_provisional_diagnosis != 'Confirmed')
		)
	end
	## callback functions
	before_save :district_tehsil_names
	def district_tehsil_names
		#Current Section
		self.district = (District.find(self.district_id).district_name rescue nil) if self.district_id.present?
		self.tehsil = (Tehsil.find(self.tehsil_id).tehsil_name rescue nil) if self.tehsil_id.present?
		self.uc = (Uc.find(self.uc_id).uc_name rescue nil) if self.uc_id.present?

		#Permanent Section
		self.permanent_district = (District.find(self.permanent_district_id).district_name rescue nil) if self.permanent_district_id.present?
		self.permanent_tehsil = (Tehsil.find(self.permanent_tehsil_id).tehsil_name rescue nil) if self.permanent_tehsil_id.present?
		self.permanent_uc = (Uc.find(self.permanent_uc_id).uc_name rescue nil) if self.permanent_uc_id.present?

		#Workplace Section
		self.workplace_district = (District.find(self.workplace_district_id).district_name rescue nil) if self.workplace_district_id.present?
		self.workplace_tehsil = (Tehsil.find(self.workplace_tehsil_id).tehsil_name rescue nil) if self.workplace_tehsil_id.present?
		self.workplace_uc = (Uc.find(self.workplace_uc_id).uc_name rescue nil) if self.workplace_uc_id.present?
	end

	def lab_result_hospital_wise_user
		# if self.persisted? and self.entered_by == "By Lab"
		# 	if lab_result.present?
		# 		if provisional_diagnosis == "Confirmed" and (lab_result.ns1 != "Positive" and lab_result.igm != "Positive" and lab_result.pcr != "Positive" and lab_result.igg != "Positive")
		# 			errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed if none of the results are positive")
		# 		elsif provisional_diagnosis == "Probable" and (lab_result.ns1 == "Positive" or lab_result.pcr == "Positive")
		# 			errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable if either NS1 or PCR is positive")
		# 		elsif provisional_diagnosis == "Probable" and (lab_result.igg == "Positive" or lab_result.igm == "Positive")
		# 			errors.add(:provisional_diagnosis, "Patient cannot be marked as probable if IGM or IGG is positive.")
		# 		elsif lab_result.warning_signs.nil? and provisional_diagnosis == "Confirmed" and user_id.present?
		# 			lab_result.errors.add(:warning_signs, "Please select presence of warning signs")
		# 		end
		# 	end
		# else
		# 	if lab_result.present?
		# 		if provisional_diagnosis == "Confirmed" and (lab_result.ns1 != "Positive" and lab_result.igm != "Positive" and lab_result.pcr != "Positive" and lab_result.igg != "Positive")
		# 			errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed if none of the results are positive")
		# 		elsif provisional_diagnosis == "Probable" and (lab_result.ns1 == "Positive" or lab_result.igm == "Positive" or lab_result.pcr == "Positive" or lab_result.igg == "Positive")
		# 			errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable if any of the results is positive")
		# 		elsif lab_result.warning_signs.nil? and provisional_diagnosis == "Confirmed" and user_id.present?
		# 			lab_result.errors.add(:warning_signs, "Please select presence of warning signs")
		# 		end
		# 	else
		# 	end
		# end
		if lab_result.present?
			if provisional_diagnosis == "Confirmed" and (lab_result.ns1 != "Positive" and lab_result.igm != "Positive" and lab_result.pcr != "Positive" and lab_result.igg != "Positive")
				errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed if none of the results are positive")
			elsif provisional_diagnosis == "Probable" and (lab_result.ns1 == "Positive" or lab_result.pcr == "Positive")
				errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable if either NS1 or PCR is positive")
			elsif provisional_diagnosis == "Probable" and (lab_result.igg == "Positive" or lab_result.igm == "Positive")
				errors.add(:provisional_diagnosis, "Patient cannot be marked as probable if IGM or IGG is positive.")
			elsif lab_result.warning_signs.nil? and provisional_diagnosis == "Confirmed" and user_id.present?
				lab_result.errors.add(:warning_signs, "Please select presence of warning signs")
			end
		end
	end
	def lab_result_lab_wise_user
		if change_by_request.present? and change_by_request.lab_user?
			if lab_result.present?
				if provisional_diagnosis == "Probable"
					if (lab_result.present? and (lab_result.ns1 == "Positive" or lab_result.pcr == "Positive"))
						errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable if either NS1 or PCR is positive")
					else
						if lab_result.igm == "Positive" and lab_result.igg == "Positive"
							if (lab_result.igg_first_reading.present? and lab_result.igm_first_reading.present? and lab_result.igg_second_reading.present? and lab_result.igm_second_reading.present?)
								if ((lab_result.igg_second_reading > lab_result.igg_first_reading) and (lab_result.igm_second_reading > lab_result.igm_first_reading))
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable because second readings are greater than the first, so please change it to Confirmed.")
								elsif ((lab_result.igg_second_reading > lab_result.igg_first_reading) and (lab_result.igm_second_reading <= lab_result.igm_first_reading))
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable because second readings are greater than the first, so please change it to Confirmed.")
								elsif ((lab_result.igg_second_reading <= lab_result.igg_first_reading) and (lab_result.igm_second_reading > lab_result.igm_first_reading))
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable because second readings are greater than the first, so please change it to Confirmed.")
								elsif ((lab_result.igg_second_reading <= lab_result.igg_first_reading) and (lab_result.igm_second_reading <= lab_result.igm_second_reading))
									# NO ERROR IN THIS CASE. PATIENT SHOULD BE ABLE TO SAVE IN PROBABLE PD
									puts "==========================================****NO ERROR****==========================================================="
								end
							else
							end

						elsif lab_result.igm == "Positive" and lab_result.igg != "Positive"
							if (lab_result.igm_first_reading.present? and lab_result.igm_second_reading.present?)
								if (lab_result.igm_second_reading > lab_result.igm_first_reading)
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable because second readings are greater than the first, so please change it to Confirmed.")
								elsif (lab_result.igm_second_reading <= lab_result.igm_first_reading)
									# NO ERROR IN THIS CASE. PATIENT SHOULD BE ABLE TO SAVE IN PROBABLE PD
									puts "==========================================****NO ERROR****==========================================================="
								end
							else
							end

						elsif lab_result.igm != "Positive" and lab_result.igg == "Positive"
							if (lab_result.igg_first_reading.present? and lab_result.igg_second_reading.present?)
								if (lab_result.igg_second_reading > lab_result.igg_first_reading)
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable because second readings are greater than the first, so please change it to Confirmed.")
								elsif (lab_result.igg_second_reading <= lab_result.igg_first_reading)
									# NO ERROR IN THIS CASE. PATIENT SHOULD BE ABLE TO SAVE IN PROBABLE PD
									puts "==========================================****NO ERROR****==========================================================="
								end
							else
							end
						else
							# errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be probable if either NS1 or PCR is positive")
						end
					end # END ns1 positive or pcr positive

				elsif provisional_diagnosis == "Confirmed"
					if lab_result.present?
						if lab_result.igm == "Positive" and lab_result.igg == "Positive"
							if (lab_result.igg_first_reading.present? and lab_result.igm_first_reading.present? and lab_result.igg_second_reading.present? and lab_result.igm_second_reading.present?)
								if ((lab_result.igg_second_reading > lab_result.igg_first_reading) and (lab_result.igm_second_reading > lab_result.igm_first_reading))
									puts "==========================================****NO ERROR****==========================================================="
								elsif ((lab_result.igg_second_reading > lab_result.igg_first_reading) and (lab_result.igm_second_reading <= lab_result.igm_first_reading))
									puts "==========================================****NO ERROR****==========================================================="
								elsif ((lab_result.igg_second_reading <= lab_result.igg_first_reading) and (lab_result.igm_second_reading > lab_result.igm_first_reading))
									puts "==========================================****NO ERROR****==========================================================="
								elsif ((lab_result.igg_second_reading <= lab_result.igg_first_reading) and (lab_result.igm_second_reading <= lab_result.igm_second_reading))
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed because second readings are less than the first, so please change it to probable.")
								end
							else
								errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed because readings are missing")
							end

						elsif lab_result.igm == "Positive" and lab_result.igg != "Positive"
							if (lab_result.igm_first_reading.present? and lab_result.igm_second_reading.present?)
								if (lab_result.igm_second_reading > lab_result.igm_first_reading)
									puts "==========================================****NO ERROR****==========================================================="
								elsif (lab_result.igm_second_reading <= lab_result.igm_first_reading)
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed because second readings are less than the first")
								end
								# New else for update case
							else
								errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed because readings are missing")
							end

						elsif lab_result.igm != "Positive" and lab_result.igg == "Positive"
							if (lab_result.igg_first_reading.present? and lab_result.igg_second_reading.present?)
								if (lab_result.igg_second_reading > lab_result.igg_first_reading)
									puts "==========================================****NO ERROR****==========================================================="
								elsif (lab_result.igg_second_reading <= lab_result.igg_first_reading)
									errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed because second readings are less than the first")
								end
							else
								errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed because readings are missing")
							end
						elsif (lab_result.ns1 != "Positive" and lab_result.pcr != "Positive")
							errors.add(:provisional_diagnosis, "Provisional Diagnosis can not be confirmed if either NS1 or PCR is not positive")
						else
						end
					end
				end #end probable
			end #lab_result present end
		end # end change_by_request
	end # function end

	def self.deag_reviewed_options(data)
		if data == 'deag_reviewed_dengue'
			"patients.death_verify is true"
		elsif data == 'deag_reviewed_non_dengue'
			"patients.death_verify_non_dengue is true"
		elsif data == 'under_review'
			"patients.under_review is true"
		else
			"patients.death_verify is not true and patients.death_verify_non_dengue is not true and patients.under_review is not true"
		end
	end

  def death_review_status
    if self.death_verify?
      status = "Deag Reviewed - Dengue"
    elsif self.death_verify_non_dengue?
      status = "Deag Reviewed - Non Dengue"
    else
      status =  self.under_review? ? "Pending | Under Reviewed" : "Pending"
    end

    return status
  end

	## remove extra spaces
	auto_strip_attributes :comments, :passport, squish: true

	before_save :provisional_diagnosis_confirmed, if: Proc.new{|obj| obj.provisional_diagnosis == "Confirmed"}
	before_save :update_patient_status, if: Proc.new{|obj| obj.patient_outcome.present? and is_hospital_user?(obj)}
	def update_patient_status
		if ['Admitted', 'Outpatient'].include?(self.patient_outcome)
			self.patient_status = 'In Process'
			self.is_released = false if self.is_released.present?
		else
			self.patient_status = 'Closed'
		end
	end


	def provisional_diagnosis_confirmed
		(self.confirmation_date = Time.now.to_datetime) unless self.confirmation_date.present?
	end
	def current_patient_lab
		self.lab_name.present? ? self.lab_name : self.try(:lab_patient).try(:lab).try(:lab_name)
	end

  ##Death Patient Notification Generate
  before_save :create_notification_if_death, if: -> { provisional_diagnosis == "Confirmed" && patient_outcome == 'Death'}
	# after_save :send_sms_if_death, if: -> { provisional_diagnosis == "Confirmed" && patient_outcome == 'Death'}
  def create_notification_if_death
    if is_master_user?
      if provisional_diagnosis_changed? or patient_outcome_changed?
        generate_users_notifications
      end
    else
      generate_users_notifications if patient_outcome_changed?
    end
  end
  def generate_users_notifications
    User.select(:id, :role, :district_id).death_notification_users.find_each do |user|
      if user.district_user?
        create_patient_notification(user) if district_id == user.district_id
      else
        create_patient_notification(user)
      end
    end
  end
  def create_patient_notification(user)
    notifications.build(
      recipient_id: user.id,
      recipient_type: 'User',
      sender_id: request_user_id,
      sender_type: 'User',
      notifiable_type: 'Patient',
      message: "#{patient_name} expired at #{death_date}"
    )
  end

	# def send_sms_if_death
	# 	require 'idi_sms'
	# 	## production sender list set in enviornment .bashrc 03244453477,03458411675,03004552474,03004290074,03352563301,03054497066,03227280599,03136019946,03334100893,03216639672,03224782678,03234417656,03328005876
	# 	number_list = Rails.env.development? ? '03216639672' : ENV['ALERT_NUMBER_LIST']
	# 	if number_list
	# 		senders_list = number_list.split(',')
	# 		senders_list.each do |phone_no|
	# 			sms_sender = IdiSms::SmsSender.new(Rails.env.to_sym)
	# 			sms_text = "Death of Dengue Confirmed Patient has been reported by #{self.hospital}. The patient ID is #{self.id}. For details, please visit Dengue Tracking System."
	# 			sms_language = "english"
	# 			sms_response = sms_sender.send_sms(phone_no, sms_text, sms_language)
	# 			# puts "===============================================#{sms_response}"
	# 		end
	# 	end
	# end
  # -------------------------------------\\\\End Death Patient Nofitication///------------------------------------------
	before_save :downcase_fields
	before_save :update_names_throu_ids

	## BEDS COUNT
	before_create :create_beds, if: Proc.new{|obj| is_hospital_user?(obj) or is_epc_user?(obj)}
	before_update :update_beds, if: Proc.new{|obj| is_hospital_user?(obj) or is_epc_user?(obj)}
	before_destroy :delete_beds, if: Proc.new{|obj| is_epc_user?(obj)}

	def update_names_throu_ids
		(self.hospital = Hospital.find(self.hospital_id).try(:hospital_name)) if hospital_id.present?
	end

	# def self.untagged_patient_data(tehsil_ids)
	# 	c1 = "(tehsil_id IN(?) and (residence_tagged is not true))"
	# 	c2 = "(workplace_tehsil_id IN(?) and (workplace_tagged is not true))"
	# 	c3 = "(permanent_tehsil_id IN(?) and (permanent_residence_tagged is not true))"
	# 	# c4 = "(provisional_diagnosis = 3)"
	# 	patients_data = Patient.get_patient_activities_prov_diag.where("( #{c1} or #{c2} or #{c3} )", tehsil_ids, tehsil_ids, tehsil_ids).ascending
	# 	return patients_data
	# end

	# def self.tagged_patients(tehsil_ids)
	# 	c1 = "(tehsil_id IN(?) and residence_tagged is true)"
	# 	c2 = "(workplace_tehsil_id IN(?) and workplace_tagged is true)"
	# 	c3 = "(permanent_tehsil_id IN(?) and permanent_residence_tagged is true)"
	# 	# c4 = "(provisional_diagnosis = 3)"

	# 	patients_data = Patient.get_patient_activities_prov_diag.where("( #{c1} or #{c2} or #{c3} )", tehsil_ids, tehsil_ids, tehsil_ids).ascending
	# 	return patients_data
	# end

	def self.untagged_generate_patient_list(patient, user_tehsils, place_type)
		patients_list = []

		( patients_list << self.generate_list_untagged_json(patient, 'residence', patient.residence_count, patient.address, patient.uc, patient.uc_id, patient.tehsil, patient.tehsil_id) ) if place_type == 'residence' and (patient.tehsil_id.present? and !patient.residence_tagged? and patient.address.present? and user_tehsils.include? patient.tehsil_id)

		( patients_list << self.generate_list_untagged_json(patient, 'workplace', patient.workplace_count, patient.workplace_address, patient.workplace_uc, patient.workplace_uc_id, patient.workplace_tehsil, patient.workplace_tehsil_id) ) if place_type == 'workplace' and (patient.workplace_tehsil_id.present? and !patient.workplace_tagged? and patient.workplace_address.present? and user_tehsils.include? patient.workplace_tehsil_id)

		( patients_list << self.generate_list_untagged_json(patient, 'permanent', patient.permanent_count, patient.permanent_address, patient.permanent_uc, patient.permanent_uc_id, patient.permanent_tehsil, patient.permanent_tehsil_id) ) if place_type == 'permanent' and (patient.permanent_tehsil_id.present? and !patient.permanent_residence_tagged? and patient.permanent_address.present? and user_tehsils.include? patient.permanent_tehsil_id)

	  return patients_list.flatten
  	end

	def self.tagged_generate_patient_list(patient, user_tehsils, place_type)
		patients_list = []

	  	( patients_list << self.generate_list_json(patient, 'residence', patient.residence_count, patient.address, patient.uc, patient.uc_id, patient.tehsil, patient.tehsil_id) ) if place_type == 'residence' and (patient.tehsil_id.present? and patient.residence_tagged? and user_tehsils.include? patient.tehsil_id)
	  	( patients_list << self.generate_list_json(patient, 'workplace', patient.workplace_count, patient.workplace_address, patient.workplace_uc, patient.workplace_uc_id, patient.workplace_tehsil, patient.workplace_tehsil_id) ) if place_type == 'workplace' and (patient.workplace_tehsil_id.present? and patient.workplace_tagged? and user_tehsils.include? patient.workplace_tehsil_id)
	  	( patients_list << self.generate_list_json(patient, 'permanent', patient.permanent_count, patient.permanent_address, patient.permanent_uc, patient.permanent_uc_id, patient.permanent_tehsil, patient.permanent_tehsil_id) ) if place_type == 'permanent' and  (patient.permanent_tehsil_id.present? and patient.permanent_residence_tagged? and user_tehsils.include? patient.permanent_tehsil_id)

	  	return patients_list.flatten
  	end

	def self.generate_list_json(patient_obj, patient_place, tag_count,  patient_address, patient_uc, patient_uc_id, patient_town, patient_town_id)

		{
			patient_id: patient_obj.id,
			patient_name: patient_obj.patient_name,
			patient_cnic_number:  patient_obj.cnic,
			patient_cnic_relation:  patient_obj.cnic_relation,
			patient_contact_number:  patient_obj.patient_contact,
			patient_phone_relation:  patient_obj.relation_contact,
			provisional_diagnosis: patient_obj.provisional_diagnosis,
			patient_address:  patient_address,
			patient_uc:  patient_uc,
			patient_uc_id:  patient_uc_id,
			patient_town: patient_town,
			patient_town_id: patient_town_id,
			tag_count: tag_count,
			patient_place: patient_place,
			confirmation_date: patient_obj.confirmation_date.present? ? ApplicationController.helpers.datetime(patient_obj.confirmation_date): "",
			is_tagged: 1,
			residence_lat: patient_obj.residence_lat,
			residence_long: patient_obj.residence_long,
			workplace_lat: patient_obj.workplace_lat,
			workplace_long: patient_obj.workplace_long,
			permanent_lat: patient_obj.permanent_lat,
			permanent_long: patient_obj.permanent_long,
			radius: patient_obj.radius
		}
	end

	def self.generate_list_untagged_json(patient_obj, patient_place, tag_count,  patient_address, patient_uc, patient_uc_id, patient_town, patient_town_id)

		{
			patient_id: patient_obj.id,
			patient_name: patient_obj.patient_name,
			patient_cnic_number:  patient_obj.cnic,
			patient_cnic_relation:  patient_obj.cnic_relation,
			patient_contact_number:  patient_obj.patient_contact,
			patient_phone_relation:  patient_obj.relation_contact,
			provisional_diagnosis: patient_obj.provisional_diagnosis,
			patient_address:  patient_address,
			patient_uc:  patient_uc,
			patient_uc_id:  patient_uc_id,
			patient_town: patient_town,
			patient_town_id: patient_town_id,
			tag_count: tag_count,
			patient_place: patient_place,
			confirmation_date: patient_obj.confirmation_date.present? ? ApplicationController.helpers.datetime(patient_obj.confirmation_date): "",
			is_tagged: 0,
			residence_lat: patient_obj.residence_lat,
			residence_long: patient_obj.residence_long,
			workplace_lat: patient_obj.workplace_lat,
			workplace_long: patient_obj.workplace_long,
			permanent_lat: patient_obj.permanent_lat,
			permanent_long: patient_obj.permanent_long,
			radius: patient_obj.radius
		}
	end

	def downcase_fields
		self.patient_name.try(:titleize)
		self.fh_name.try(:titleize)
		self.district.try(:titleize)
		self.tehsil.try(:titleize)
		self.uc.try(:titleize)
		self.permanent_district.try(:titleize)
		self.permanent_tehsil.try(:titleize)
		self.permanent_uc.try(:titleize)
		self.workplace_district.try(:titleize)
		self.workplace_tehsil.try(:titleize)
		self.workplace_uc.try(:titleize)
		self.passport.try(:titleize)
		self.province_id = (self.g_district.present? ?  self.g_district.province.id : nil)
	end
	def tag_increment(place)
		case place
		when 'residence'
		  self.residence_count+=1 if self.residence_count < 49
		  self.is_residence_household = true  if self.residence_count > 49
		when 'permanent'
		  self.permanent_count+=1 if self.permanent_count < 49
		  self.is_permanent_household = true  if self.permanent_count > 49
		when 'workplace'
		  self.workplace_count+=1 if self.workplace_count < 49
		  self.is_workplace_household = true  if self.workplace_count > 49
		end
	end
	def get_address(place)
		_address_ = ''
		case place
		when 'residence'
		 _address_ = self.address
		when 'permanent'
		  _address_ = self.permanent_address
		when 'workplace'
		  _address_ = self.workplace_address
		end
		return _address_
	end
	
	def get_p_age
		self.age > 0 ? "#{self.age} #{'Year'.pluralize(self.age)}" : "#{self.age_month} #{'Month'.pluralize(self.age_month)}"
	end

	def load_lab_patient(lab_patient)
		self.lab_patient_id = lab_patient.id
		self.patient_name = lab_patient.p_name
		self.fh_name = lab_patient.fh_name
		self.age = lab_patient.age
		self.age_month = lab_patient.month
		self.gender = lab_patient.gender
		self.cnic_relation = lab_patient.cnic_type
		self.cnic = lab_patient.cnic
		self.patient_contact = lab_patient.contact_no
		self.relation_contact = lab_patient.other_contact_noputs
		self.permanent_district = lab_patient.perm_district
		self.permanent_district_id = lab_patient.perm_district_id
		self.permanent_tehsil = lab_patient.perm_tehsil
		self.permanent_tehsil_id = lab_patient.perm_tehsil_id
		self.permanent_uc = lab_patient.perm_uc
		self.permanent_uc_id = lab_patient.perm_uc_id

		## workplace
		self.workplace_address = lab_patient.workplc_address
		self.workplace_district = lab_patient.workplc_district
		self.workplace_district_id = lab_patient.workplc_district_id
		self.workplace_tehsil = lab_patient.workplc_tehsil
		self.workplace_tehsil_id = lab_patient.workplc_tehsil_id
		self.workplace_uc = lab_patient.workplc_uc
		self.workplace_uc_id		 = lab_patient.workplc_uc_id

		## labresults
			# FIRST READING
			self.lab_result.hct_first_reading = lab_patient.hct_first_reading
			self.lab_result.hct_first_reading_date = lab_patient.hct_first_reading_date
			self.lab_result.wbc_first_reading = lab_patient.wbc_first_reading
			self.lab_result.wbc_first_reading_date = lab_patient.wbc_first_reading_date
			self.lab_result.platelet_first_reading = lab_patient.platelet_first_reading
			self.lab_result.platelet_first_reading_date = lab_patient.platelet_first_reading_date

			# SECOND READING
			self.lab_result.hct_second_reading = lab_patient.hct_second_reading
			self.lab_result.hct_second_reading_date = lab_patient.hct_second_reading_date
			self.lab_result.wbc_second_reading = lab_patient.wbc_second_reading
			self.lab_result.wbc_second_reading_date = lab_patient.wbc_second_reading_date
			self.lab_result.platelet_second_reading = lab_patient.platelet_second_reading
			self.lab_result.platelet_second_reading_date = lab_patient.platelet_second_reading_date

			# THIRD READING
			self.lab_result.hct_third_reading = lab_patient.hct_third_reading
			self.lab_result.hct_third_reading_date = lab_patient.hct_third_reading_date
			self.lab_result.wbc_third_reading = lab_patient.wbc_third_reading
			self.lab_result.wbc_third_reading_date = lab_patient.wbc_third_reading_date
			self.lab_result.platelet_third_reading = lab_patient.platelet_third_reading
			self.lab_result.platelet_third_reading_date = lab_patient.platelet_third_reading_date

		## LAB AND DIAGNOSTIC INFORMATION
		self.lab_result.ns1 = lab_patient.ns_1
		self.lab_result.pcr = lab_patient.pcr
		self.lab_result.igm = lab_patient.igm
		self.lab_result.igg = lab_patient.igg
		self.reporting_date = lab_patient.reporting_date
		self.confirmation_date = lab_patient.confirmation_date
		self.comments = lab_patient.comments
	end


	## Generate Bed
	def create_beds
		bed = Bed.find_by_hospital_id(hospital_id)
		bed = Bed.new(hospital_id: hospital_id) unless bed.present?
		bed = new_bed(bed)
		bed.last_admitted_at = Time.now if ['Probable', 'Suspected', 'Confirmed'].include?(provisional_diagnosis) and patient_outcome == 'Admitted'
		bed.save
	end

	def update_beds
		bed = Bed.find_by_hospital_id(hospital_id)
		bed = Bed.new(hospital_id: hospital_id) unless bed.present?
		# call the function to populate values in last admitted_date and last_discharged_date
		populate_last_admitted_and_last_discharged_values(bed)
		# call the function to populate values in last admitted_date and last_discharged_date
		if ( (patient_outcome == patient_outcome_was) and (provisional_diagnosis == provisional_diagnosis_was) and (patient_condition == patient_condition_was))
			puts "<<<<<<<<<<<<<<<<<<<<<<<<<< NO CHANGED >>>>>>>>>>>>>>>>>"
			if (bed.occupied_hdu_beds == 0 and bed.occupied_ward_beds == 0)
				puts "first entry ............................."
				bed = new_bed(bed)
				if bed.save
					puts "=== first entry saved"
				else
					puts "==========first entry = #{bed.errors.full_messages}"
				end
			end
		else
			# puts "====================================================="
			# puts "#{patient_outcome} .... #{patient_outcome_was}"
			# puts "====================================================="

			if provisional_diagnosis == 'Confirmed'
				puts "========================================================="
				puts "========================================================="
				puts ""
				puts ""
				puts ""
				puts ""
				puts "#{patient_outcome}, #{provisional_diagnosis_was}, #{patient_condition}"
				puts ""
				puts ""
				puts ""
				puts ""
				puts "========================================================="
				puts "========================================================="
				## Non Dengue to Confirm Patient Admitted
				if provisional_diagnosis_was == 'Non-Dengue' and patient_outcome == 'Admitted'
					puts "======== 'Non Dengue to Confirm Patient Admitted"
					if patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1  ## go to stable condition
					elsif patient_condition == 'Stable'
						bed.occupied_ward_beds = bed.occupied_ward_beds + 1 ## go to critical condition
					end
				## 'Probable', 'Suspected' to Confirm Patient. >> if prob,sus is admitted and same move on confirm
				elsif ['Probable', 'Suspected'].include?(provisional_diagnosis_was) and patient_outcome_was == 'Admitted' and patient_outcome == 'Admitted'
					puts "======== ' 'Probable', 'Suspected' to Confirm Patient Admitted"
					if patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1  ## go to critical condition
						bed.occupied_ward_beds = bed.occupied_ward_beds - 1  ## go to stable condition
					end
				elsif ['Probable', 'Suspected'].include?(provisional_diagnosis_was) and patient_outcome_was != 'Admitted' and patient_outcome == 'Admitted'
					puts "======== ' 'Probable', 'Suspected' to Confirm Patient was not Admitted previous status"
					if patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1  ## go to stable condition
					elsif patient_condition == 'Stable'
						bed.occupied_ward_beds = bed.occupied_ward_beds + 1 ## go to critical condition
					end
				## if Admitted to (Discharg , Death, LAMA)
				elsif patient_outcome_was == 'Admitted' and ['Discharged', 'Death', 'LAMA', 'Outpatient'].include?(patient_outcome)
					puts "================ Admitted to (Discharg , Death, LAMA)"
					if patient_condition_was == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds - 1  ## go to stable condition
					elsif patient_condition_was == 'Stable'
						bed.occupied_ward_beds = bed.occupied_ward_beds - 1 ## go to critical condition
					end
				## Admitted to OutPatient
				elsif patient_outcome_was == 'Admitted' and patient_outcome == 'Outpatient'
					puts "================ Admitted to OutPatient"
					if patient_condition_was == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds - 1  ## go to stable condition
					elsif patient_condition_was == 'Stable'
						bed.occupied_ward_beds = bed.occupied_ward_beds - 1 ## go to critical condition
					end
				## Discharg , Death, LAMA to OutPatient
				elsif patient_outcome == 'Outpatient' and ['Discharged', 'Death', 'LAMA'].include?(patient_outcome_was)
					puts "================= not effect"
				## OutPatient to Discharg , Death, LAMA
				elsif patient_outcome_was == 'Outpatient' and ['Discharged', 'Death', 'LAMA'].include?(patient_outcome)
					puts "================= not effect"
					## Discharg , Death, LAMA to Admitted
				elsif patient_outcome == 'Admitted' and ['Discharged', 'Death', 'LAMA', 'Outpatient'].include?(patient_outcome_was)
					puts "================= convert condition changed /???????????????????????????"
					if patient_condition_was != patient_condition and patient_condition_was == 'Critical' and patient_condition == 'Stable'
						bed.occupied_ward_beds = bed.occupied_ward_beds + 1 ## go to critical condition
					elsif patient_condition_was != patient_condition and patient_condition_was == 'Stable' and patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1  ## go to stable condition
					elsif patient_condition_was == patient_condition and patient_condition == 'Stable'
						bed.occupied_ward_beds = bed.occupied_ward_beds + 1 ## go to critical condition
					elsif patient_condition_was == patient_condition and patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1  ## go to stable condition
					end
				elsif ( (patient_outcome_was == 'Admitted' and patient_outcome == 'Admitted') and (patient_condition_was.present? and patient_condition_was != patient_condition) )
					if patient_condition_was == 'Critical' and patient_condition == 'Stable'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds - 1
						bed.occupied_ward_beds = bed.occupied_ward_beds + 1
					elsif patient_condition_was == 'Stable' and patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1
						bed.occupied_ward_beds = bed.occupied_ward_beds - 1
					end
				elsif ( (patient_outcome_was == nil or patient_outcome_was == "") and patient_outcome_was != patient_outcome and patient_outcome == 'Admitted')
					puts "================ done"
					if patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1  ## go to stable condition
					elsif patient_condition == 'Stable'
						bed.occupied_ward_beds = bed.occupied_ward_beds + 1 ## go to critical condition
					end
				end
			else
				bed = not_discharg(bed)
			end
				bed.occupied_hdu_beds = 0 if bed.occupied_hdu_beds < 0
				bed.occupied_ward_beds = 0 if bed.occupied_ward_beds < 0
			bed.save
		end
	end
	def not_discharg(bed)
		## if PV = PROB
		if ['Probable', 'Suspected'].include?(provisional_diagnosis)
			## From Non Dengue to Admitted
			if provisional_diagnosis_was == 'Non-Dengue' and patient_outcome == 'Admitted'
				puts "======== 'Non Dengue to Admitted"
				bed.occupied_ward_beds = bed.occupied_ward_beds + 1
			#Out Patient to Discharge, Death, LAMA
			elsif patient_outcome_was == 'Outpatient' and ['Discharged', 'Death', 'LAMA'].include?(patient_outcome)
			## Admitted to 'Discharged', 'Death', 'LAMA', 'Outpatient'
			elsif patient_outcome_was == 'Admitted' and ['Discharged', 'Death', 'LAMA', 'Outpatient'].include?(patient_outcome)
				puts "======== Admitted to 'Discharged', 'Death', 'LAMA', 'Outpatient"
				bed.occupied_ward_beds = bed.occupied_ward_beds - 1
			## Discharged', 'Death', 'LAMA', 'Outpatient' to Admitted
			elsif ['Discharged', 'Death', 'LAMA', 'Outpatient'].include?(patient_outcome_was) and patient_outcome == 'Admitted'
				puts "======== 'Discharged', 'Death', 'LAMA', 'Outpatient to Admitted"
				bed.occupied_ward_beds = bed.occupied_ward_beds + 1
			elsif (patient_outcome != patient_outcome_was and patient_outcome == 'Admitted' and lab_user_id != nil)
				bed.occupied_ward_beds = bed.occupied_ward_beds + 1
			else
				puts "==================== else condition 1"
				puts "===============#{patient_outcome}, #{provisional_diagnosis}"
			end
		elsif provisional_diagnosis == 'Non-Dengue'
			## if PV suspected or probable and patient outcome admitted it should be released
			if ['Suspected', 'Probable'].include?(provisional_diagnosis_was) and patient_outcome_was == 'Admitted'
				puts "============== if PV suspected or probable and patient outcome admitted it should be released"
				bed.occupied_ward_beds = bed.occupied_ward_beds - 1
			end
		end

		bed.occupied_hdu_beds = 0 if bed.occupied_hdu_beds < 0
		return bed
	end
	def new_bed(bed)
		if patient_outcome == 'Admitted' and provisional_diagnosis != 'Non-Dengue'
			if ['Suspected', 'Probable'].include?(provisional_diagnosis)
				bed.occupied_ward_beds = bed.occupied_ward_beds + 1
			elsif provisional_diagnosis == 'Confirmed'
				if patient_condition == 'Critical'
					bed.occupied_hdu_beds = bed.occupied_hdu_beds + 1
				else
					bed.occupied_ward_beds = bed.occupied_ward_beds + 1
				end
			end
		end
		return bed
	end

	def populate_last_admitted_and_last_discharged_values(bed)
		if provisional_diagnosis_changed? or patient_outcome_changed?
			if provisional_diagnosis == 'Confirmed' and patient_outcome == 'Admitted'
				bed.last_admitted_at = Time.now if patient_outcome_was != patient_outcome # do not re populate the value if it is there already
			elsif provisional_diagnosis == 'Confirmed' and patient_outcome == 'Discharged'
				bed.last_discharged_at = Time.now if patient_outcome_was != patient_outcome # do not re populate the value if it is there already
			elsif provisional_diagnosis == 'Suspected' and patient_outcome == 'Admitted'
				bed.last_admitted_at = Time.now if patient_outcome_was != patient_outcome # do not re populate the value if it is there already
			elsif provisional_diagnosis == 'Suspected' and patient_outcome == 'Discharged'
				bed.last_discharged_at = Time.now if patient_outcome_was != patient_outcome # do not re populate the value if it is there already
			elsif  provisional_diagnosis == 'Probable' and patient_outcome == 'Admitted'
				bed.last_admitted_at = Time.now if patient_outcome_was != patient_outcome # do not re populate the value if it is there already
			elsif provisional_diagnosis == 'Probable' and patient_outcome == 'Discharged'
				bed.last_discharged_at = Time.now if patient_outcome_was != patient_outcome # do not re populate the value if it is there already
			end
		end
	end

	def delete_beds
		bed = Bed.find_by_hospital_id(hospital_id)
		if bed.present?
			if patient_outcome == 'Admitted'
				if ['Suspected', 'Probable'].include?(provisional_diagnosis)
					bed.occupied_ward_beds = bed.occupied_ward_beds - 1
				elsif provisional_diagnosis == 'Confirmed'
					if patient_condition == 'Critical'
						bed.occupied_hdu_beds = bed.occupied_hdu_beds - 1
					else
						bed.occupied_ward_beds = bed.occupied_ward_beds - 1
					end
				end
				bed.occupied_hdu_beds = 0 if bed.occupied_hdu_beds < 0
				bed.occupied_ward_beds = 0 if bed.occupied_ward_beds < 0
				# puts "=================================================== deleted #{}"
				bed.save
			end
		end
	end

	before_create :register_test_logs, if: Proc.new{|obj| updated_by.present?}

	def register_test_logs
		test_log = TestLog.new

		# FIRST READING
		test_log.hct_first_reading = lab_result.hct_first_reading
		test_log.hct_first_reading_date = lab_result.hct_first_reading_date
		test_log.wbc_first_reading = lab_result.wbc_first_reading
		test_log.wbc_first_reading_date = lab_result.wbc_first_reading_date
		test_log.platelet_first_reading = lab_result.platelet_first_reading
		test_log.platelet_first_reading_date = lab_result.platelet_first_reading_date

		# SECOND READING
		test_log.hct_second_reading = lab_result.hct_second_reading
		test_log.hct_second_reading_date = lab_result.hct_second_reading_date
		test_log.wbc_second_reading = lab_result.wbc_second_reading
		test_log.wbc_second_reading_date = lab_result.wbc_second_reading_date
		test_log.platelet_second_reading = lab_result.platelet_second_reading
		test_log.platelet_second_reading_date = lab_result.platelet_second_reading_date

		# THIRD READING
		test_log.hct_third_reading = lab_result.hct_third_reading
		test_log.hct_third_reading_date = lab_result.hct_third_reading_date
		test_log.wbc_third_reading = lab_result.wbc_third_reading
		test_log.wbc_third_reading_date = lab_result.wbc_third_reading_date
		test_log.platelet_third_reading = lab_result.platelet_third_reading
		test_log.platelet_third_reading_date = lab_result.platelet_third_reading_date

		## LAB AND DIAGNOSTIC INFORMATION
		test_log.ns1 = lab_result.ns1
		test_log.pcr = lab_result.pcr
		test_log.igm = lab_result.igm
		test_log.igg = lab_result.igg
		test_log.provisional_diagnosis = self.provisional_diagnosis
		test_log.change_by = updated_by.try(:username)
		test_log.reporting_date = self.reporting_date
		test_log.comments = self.comments
		test_log.patient_id = self.id
		test_log.patient_name = self.patient_name
		test_log.cnic = self.cnic
		test_log.passport = self.passport
		test_log.save
	end

	### confirmation by
	before_save :update_confirmation_date, unless: Proc.new{|obj| obj.confirmation_id.present?}
	def update_confirmation_date
		if self.provisional_diagnosis == 'Confirmed' and updated_id.present?
			self.confirmation_id = updated_id
			self.confirmation_role = updated_by.lab_user? ? 'Confirmed by Lab' : 'Confirmed by Hospital'
		end
	end

	before_update :change_test_logs, if: Proc.new{|obj| updated_by.present?}

	def change_test_logs
		test_log = TestLog.new
		is_changed = false
		# FIRST READING
		begin
			if lab_result.present?
				if lab_result.hct_first_reading_was != lab_result.hct_first_reading
					(test_log.hct_first_reading = lab_result.hct_first_reading_was)
					is_changed = true
				end
				if lab_result.hct_first_reading_date_was != lab_result.hct_first_reading_date
					(test_log.hct_first_reading_date = lab_result.hct_first_reading_date_was)
					is_changed = true
				end
				if lab_result.wbc_first_reading_was != lab_result.wbc_first_reading
					(test_log.wbc_first_reading = lab_result.wbc_first_reading_was)
					is_changed = true
				end
				if lab_result.wbc_first_reading_date_was != lab_result.wbc_first_reading_date
					(test_log.wbc_first_reading_date = lab_result.wbc_first_reading_date_was)
					is_changed = true
				end
				if lab_result.platelet_first_reading_was != lab_result.platelet_first_reading
					(test_log.platelet_first_reading = lab_result.platelet_first_reading_was)
					is_changed = true
				end
				if lab_result.platelet_first_reading_date_was != lab_result.platelet_first_reading_date
					(test_log.platelet_first_reading_date = lab_result.platelet_first_reading_date_was)
					is_changed = true
				end

				# SECOND READING
				if lab_result.hct_second_reading_was != lab_result.hct_second_reading
					(test_log.hct_second_reading = lab_result.hct_second_reading_was)
					is_changed = true
				end
				if lab_result.hct_second_reading_date_was != lab_result.hct_second_reading_date
					(test_log.hct_second_reading_date = lab_result.hct_second_reading_date_was)
					is_changed = true
				end
				if lab_result.wbc_second_reading_was != lab_result.wbc_second_reading
					(test_log.wbc_second_reading = lab_result.wbc_second_reading_was)
					is_changed = true
				end
				if lab_result.wbc_second_reading_date_was != lab_result.wbc_second_reading_date
					(test_log.wbc_second_reading_date = lab_result.wbc_second_reading_date_was)
					is_changed = true
				end
				if lab_result.platelet_second_reading_was != lab_result.platelet_second_reading
					(test_log.platelet_second_reading = lab_result.platelet_second_reading_was)
					is_changed = true
				end
				if lab_result.platelet_second_reading_date_was != lab_result.platelet_second_reading_date
					(test_log.platelet_second_reading_date = lab_result.platelet_second_reading_date_was)
					is_changed = true
				end

				# THIRD READING
				if lab_result.hct_third_reading_was != lab_result.hct_third_reading
					(test_log.hct_third_reading = lab_result.hct_third_reading_was)
					is_changed = true
				end
				if lab_result.hct_third_reading_date_was != lab_result.hct_third_reading_date
					(test_log.hct_third_reading_date = lab_result.hct_third_reading_date_was)
					is_changed = true
				end
				if lab_result.wbc_third_reading_was != lab_result.wbc_third_reading
					(test_log.wbc_third_reading = lab_result.wbc_third_reading_was)
					is_changed = true
				end
				if lab_result.wbc_third_reading_date_was != lab_result.wbc_third_reading_date
					(test_log.wbc_third_reading_date = lab_result.wbc_third_reading_date_was)
					is_changed = true
				end
				if lab_result.platelet_third_reading_was != lab_result.platelet_third_reading
					(test_log.platelet_third_reading = lab_result.platelet_third_reading_was)
					is_changed = true
				end
				if lab_result.platelet_third_reading_date_was != lab_result.platelet_third_reading_date
					(test_log.platelet_third_reading_date = lab_result.platelet_third_reading_date_was)
					is_changed = true
				end

				## LAB AND DIAGNOSTIC INFORMATION
				if lab_result.ns1_was != lab_result.ns1
					(test_log.ns1 = lab_result.ns1_was)
					is_changed = true
				end
				if lab_result.pcr_was != lab_result.pcr
					(test_log.pcr = lab_result.pcr_was)
					is_changed = true
				end
				if lab_result.igm != lab_result.igm
					(test_log.igm = lab_result.igm_was)
					is_changed = true
				end
				if lab_result.igg_was != lab_result.igg
					(test_log.igg = lab_result.igg_was)
					is_changed = true
				end
				if self.provisional_diagnosis_was != self.provisional_diagnosis
					(test_log.provisional_diagnosis = self.provisional_diagnosis_was)
					is_changed = true
				end
				if self.reporting_date_was != self.reporting_date
					(test_log.reporting_date = self.reporting_date_was)
					is_changed = true
				end
				if self.comments_was != self.comments
					(test_log.comments = self.comments_was)
					is_changed = true
				end
				if is_changed
					(test_log.change_by = updated_by.try(:username))
					test_log.patient_id = self.id
					test_log.patient_name = self.patient_name
					test_log.cnic = self.cnic
					test_log.passport = self.passport
					test_log.save
				end
			end
		end
	end

	def is_hospital_user?(obj)
		(obj.updated_by.present? and obj.updated_by.hospital_user?)
	end
	def is_lab_user?(obj)
		(obj.updated_by.present? and obj.updated_by.lab_user?)
	end
	def is_epc_user?(obj)
		(obj.updated_by.present? and obj.updated_by.epc_user?)
	end
	def is_master_user?
		(change_by_request.present? and change_by_request.master_user?)
	end
	# enum provisional_diagnosis: { "Non-Dengue": 0, "Probable": 1, "Suspected": 2, "Confirmed": 3}

	def self.is_unique_identification_from_lab?(p_name, p_contact)
		patient = Patient.is_uniq_p_name(p_name).is_uniq_p_contact(p_contact)
	end

	def patient_name_and_contact_should_unique
		patient = Patient.is_unique_identification_from_lab?(self.patient_name, self.patient_contact)
		if patient.present?
			if new_record? and patient.count > 0
				puts "present or not"
				errors.add(:patient_name, "Patient Name and Phone Number already Exist")
			else
				if patient.count > 1
					errors.add(:patient_name, "Patient Name and Phone Number already Exist")
				end
			end
		end
		true
	end

	def valid_api_from_lab?
		['Admitted', 'Outpatient'].exclude?(self.patient_outcome)
	end

  def is_death_patient?
    patient_outcome == 'Death'
  end

	## CSV/XSLX/XLS

	def self.to_csv(current_user, is_empty = true)
		if is_empty == true
			if current_user.lab_user?
				patient_headers = ["Sr No.", "Patient ID", "Patient name", "Father/Husband name", "Age", "Gender", "CNIC/Passport", "Country", "Guardian's Relation", "Patient contact", "#{current_user.admin? ? 'Last Changed By' : 'Relation contact'}", "Entry Date", "Hospital/Lab", "Lab/Hospital District","Address", "District", "Tehsil", "UC", "Residence House Tagged", "Permanent address", "Permanent district", "Permanent tehsil", "Permanent UC", "Permanent House Tagged", "Workplace address", "Workplace district", "Workplace tehsil", "Workplace UC", "Workplace Tagged", "Date of onset", "Fever last for", "Fever", "Previous dengue fever", "Associated Symptoms", "Provisional diagnosis", "Confirmation Date", "Other diagnosed fever", "Patient status", "Patient condition", "Patient outcome", "Reporting Date", "Entered By", "Created By", "Lab Name","Hct First Reading", "Hct First Reading Date", "Wbc First Reading", "Wbc First Reading Date", "Platelets First Reading", "Platelets First Reading Date", "Hospital Category", "Facility Type", "Travel History"]
				CSV.generate(headers: true) do |csv|
					csv << patient_headers
					all.each_with_index do |patient, i|
						patient_row = lab_user(i, patient, current_user)
						csv << patient_row
					end
				end
			else

				patient_headers = ["Sr No.", "Patient ID", "Patient name", "Father/Husband name", "Age", "Gender", "CNIC/Passport", "Country","Guardian's Relation", "Patient contact", "#{current_user.admin? ? 'Last Changed By' : 'Relation contact'}", "Entry Date", "Hospital/Lab", "Address", "District", "Hospital District","Tehsil", "UC", "Residence House Tagged", "Permanent address", "Permanent district", "Permanent tehsil", "Permanent UC", "Permanent House Tagged", "Workplace address", "Workplace district", "Workplace tehsil", "Workplace UC", "Workplace Tagged", "Date of onset", "Fever last for", "Fever", "Previous dengue fever", "Associated Symptoms", "Provisional diagnosis", "Confirmation Date", "Other diagnosed fever", "Patient status", "Patient condition", "Patient outcome","Admission Date", "Death Date", "Discharged Date", "Reporting Date", "Entered By", "Created By", "Lab Name", "NS1","PCR","IGG","IGM","Advised Test","Report ordering date","Report receiving date", "Lab Turnaround Time", "First Report Order Date", "First Report Receiving Date", "Second Report Order Date", "Second Report Receiving Date", "Third Report Order Date", "Third Report Receiving Date", "First Turnaround Time", "Second Turnaround Time", "Third Turnaround Time", "Dengue Virus type", "Death review Status", "Hct First Reading", "Hct First Reading Date", "Wbc First Reading", "Wbc First Reading Date", "Platelets First Reading", "Platelets First Reading Date", "Diagnosis", "Diagnosis Change Date", "Hospital Category", "Facility Type","Travel History"]
				CSV.generate(headers: true) do |csv|
					csv << patient_headers
					all.each_with_index do |patient, i|
						patient_row = patient_user(i, patient, current_user)
						csv << patient_row
					end
				end
			end
		else
			if current_user.lab_user?
				patient_headers = ["Sr No.", "Patient ID", "Patient name", "Father/Husband name", "Age", "Gender", "CNIC/Passport", "Country", "Guardian's Relation", "Patient contact", "#{current_user.admin? ? 'Last Changed By' : 'Relation contact'}", "Entry Date", "Hospital/Lab", "Address", "District", "Tehsil", "UC", "Residence House Tagged", "Permanent address", "Permanent district", "Permanent tehsil", "Permanent UC", "Permanent House Tagged", "Workplace address", "Workplace district", "Workplace tehsil", "Workplace UC", "Workplace Tagged", "Date of onset", "Fever last for", "Fever", "Previous dengue fever", "Associated Symptoms", "Provisional diagnosis", "Confirmation Date", "Other diagnosed fever", "Patient status", "Patient condition", "Patient outcome", "Reporting Date", "Entered By", "Created By", "Lab Name"]
				CSV.generate(headers: true) do |csv|
					csv << patient_headers
				end
			else
				patient_headers = ["Sr No.", "Patient ID", "Patient name", "Father/Husband name", "Age", "Gender", "CNIC/Passport", "Country", "Guardian's Relation", "Patient contact", "#{current_user.admin? ? 'Last Changed By' : 'Relation contact'}", "Entry Date", "Hospital/Lab", "Address", "District", "Tehsil", "UC", "Residence House Tagged", "Permanent address", "Permanent district", "Permanent tehsil", "Permanent UC", "Permanent House Tagged", "Workplace address", "Workplace district", "Workplace tehsil", "Workplace UC", "Workplace Tagged", "Date of onset", "Fever last for", "Fever", "Previous dengue fever", "Associated Symptoms", "Provisional diagnosis", "Confirmation Date", "Other diagnosed fever", "Patient status", "Patient condition", "Patient outcome","Admission Date", "Death Date", "Discharged Date", "Reporting Date", "Entered By", "Created By", "Lab Name", "NS1","PCR","IGG","IGM","Advised Test","Report ordering date","Report receiving date", "Lab Turnaround Time", "First Report Order Date", "First Report Receiving Date", "Second Report Order Date", "Second Report Receiving Date", "Third Report Order Date", "Third Report Receiving Date", "First Turnaround Time", "Second Turnaround Time", "Third Turnaround Time", "Diagnosis", "Dengue Virus type", "Death review Status"]
				CSV.generate(headers: true) do |csv|
					csv << patient_headers
				end
			end
		end
	end

	def self.lab_user(i, patient, current_user)
		lab_district = patient.hospital.present? ? patient.admitted_hospital&.district&.district_name || "NA" : "NA"
		lab_result = patient.lab_result
		if lab_result.present?
			# New Columns in export to excel
			hct_first_reading = lab_result.hct_first_reading
			hct_first_reading_date = lab_result.hct_first_reading_date
			wbc_first_reading = lab_result.wbc_first_reading
			wbc_first_reading_date = lab_result.wbc_first_reading_date
			platelet_first_reading = lab_result.platelet_first_reading
			platelet_first_reading_date = lab_result.platelet_first_reading_date
		else
			# New Columns in export to excel
			hct_first_reading = "N/A"
			hct_first_reading_date = "N/A"
			wbc_first_reading = "N/A"
			wbc_first_reading_date = "N/A"
			platelet_first_reading = "N/A"
			platelet_first_reading_date = "N/A"
		end
		[i+1,
		patient.id,
		patient.patient_name,
		patient.fh_name,
		patient.get_p_age,
		patient.gender,
		(patient.p_search_type == 'CNIC' ? patient.cnic : patient.passport),
		patient.country,
		patient.cnic_relation,
		patient.patient_contact,
		(current_user.admin? ? ( patient.change_by_request.try(:username)) : patient.relation_contact),
		ApplicationController.helpers.datetime(patient.created_at),
		patient.hospital,
		lab_district,
		patient.address,
		patient.district,
		patient.tehsil,
		patient.uc,
		patient.residence_tagged,
		patient.permanent_address,
		patient.permanent_district,
		patient.permanent_tehsil,
		patient.permanent_uc,
		patient.permanent_residence_tagged,
		patient.workplace_address,
		patient.workplace_district,
		patient.workplace_tehsil,
		patient.workplace_uc,
		patient.workplace_tagged,
		patient.date_of_onset,
		patient.fever_last_till,
		patient.fever,
		patient.previous_dengue_fever,
		patient.associated_symptom,
		patient.provisional_diagnosis,
		ApplicationController.helpers.datetime(patient.confirmation_date),
		patient.other_diagnosed_fever,
		patient.patient_status,
		patient.patient_condition,
		patient.patient_outcome,
		(patient.reporting_date? ? ApplicationController.helpers.date(patient.reporting_date) : nil),
		patient.entered_by,
		(patient.from_lab.try(:username) || patient.user.try(:username)),
		(patient.lab_name.present? ? patient.lab_name : patient.try(:lab_patient).try(:lab).try(:lab_name)),
		hct_first_reading,
		hct_first_reading_date,
		wbc_first_reading,
		wbc_first_reading_date,
		platelet_first_reading,
		platelet_first_reading_date,
		patient.try(:admitted_hospital).try(:category),
		patient.try(:admitted_hospital).try(:facility_type),
		patient.travel_history || 'NA'
	]
	end
	def self.patient_user(i, patient, current_user)
		hospital_district = patient.hospital.present? ? patient.admitted_hospital&.district&.district_name || "NA" : "NA"
		lab_result = patient.lab_result
		if (lab_result.present? and ["Confirmed", "Probable"].include?(patient.provisional_diagnosis))
			ns1 = lab_result.ns1
			pcr = lab_result.pcr
			igg = lab_result.igg
			igm = lab_result.igm
      diagnosis = lab_result.diagnosis
      dengue_virus_type = lab_result.dengue_virus_type
		else
			ns1 = "N/A"
			pcr = "N/A"
			igg = "N/A"
			igm = "N/A"
      diagnosis = "N/A"
      dengue_virus_type = "N/A"
		end

		if lab_result.present?
			cbc_report_order_date_first 	= lab_result.cbc_report_order_date_first.strftime("on %m/%d/%Y at %I:%M%p") rescue "N/A"
			cbc_report_order_date_second 	= lab_result.cbc_report_order_date_second.strftime("on %m/%d/%Y at %I:%M%p") rescue "N/A"
			cbc_report_order_date_third 	= lab_result.cbc_report_order_date_third.strftime("on %m/%d/%Y at %I:%M%p") rescue "N/A"
			cbc_report_receiving_date_first = lab_result.cbc_report_receiving_date_first.strftime("on %m/%d/%Y at %I:%M%p") rescue "N/A"
			cbc_report_receiving_date_second = lab_result.cbc_report_receiving_date_second.strftime("on %m/%d/%Y at %I:%M%p") rescue "N/A"
			cbc_report_receiving_date_third = lab_result.cbc_report_receiving_date_third.strftime("on %m/%d/%Y at %I:%M%p") rescue "N/A"

			lab_turnaround_time = lab_result.time_diff(lab_result.lab_turnaround_time)
			cbc_turnaround_first = lab_result.time_diff(lab_result.cbc_turnaround_first)
			cbc_turnaround_second = lab_result.time_diff(lab_result.cbc_turnaround_second)
			cbc_turnaround_third = lab_result.time_diff(lab_result.cbc_turnaround_third)

			# New Columns in export to excel
			hct_first_reading = lab_result.hct_first_reading
			hct_first_reading_date = lab_result.hct_first_reading_date
			wbc_first_reading = lab_result.wbc_first_reading
			wbc_first_reading_date = lab_result.wbc_first_reading_date
			platelet_first_reading = lab_result.platelet_first_reading
			platelet_first_reading_date = lab_result.platelet_first_reading_date

			diagnosis = lab_result.diagnosis
			diagnosis_change_date = lab_result.diagnosis_change_date

		else
			cbc_report_order_date_first = "N/A"
			cbc_report_order_date_second = "N/A"
			cbc_report_order_date_third = "N/A"
			cbc_report_receiving_date_first = "N/A"
			cbc_report_receiving_date_second = "N/A"
			cbc_report_receiving_date_third = "N/A"

			lab_turnaround_time = "N/A"
			cbc_turnaround_first = "N/A"
			cbc_turnaround_second = "N/A"
			cbc_turnaround_third = "N/A"

			# New Columns in export to excel
			hct_first_reading = "N/A"
			hct_first_reading_date = "N/A"
			wbc_first_reading = "N/A"
			wbc_first_reading_date = "N/A"
			platelet_first_reading = "N/A"
			platelet_first_reading_date = "N/A"
			diagnosis = "N/A"
			diagnosis_change_date = "N/A"

		end

		[i+1,
		patient.id,
		patient.patient_name,
		patient.fh_name,
		patient.get_p_age,
		patient.gender,
		(patient.p_search_type == 'CNIC' ? patient.cnic : patient.passport),
		patient.country,
		patient.cnic_relation,
		patient.patient_contact,
		(current_user.admin? ? ( patient.change_by_request.try(:username)) : patient.relation_contact),
		ApplicationController.helpers.datetime(patient.created_at),
		patient.hospital,

		patient.address,
		patient.district,
		hospital_district,
		patient.tehsil,
		patient.uc,
		patient.residence_tagged,
		patient.permanent_address,
		patient.permanent_district,
		patient.permanent_tehsil,
		patient.permanent_uc,
		patient.permanent_residence_tagged,
		patient.workplace_address,
		patient.workplace_district,
		patient.workplace_tehsil,
		patient.workplace_uc,
		patient.workplace_tagged,
		patient.date_of_onset,
		patient.fever_last_till,
		patient.fever,
		patient.previous_dengue_fever,
		patient.associated_symptom,
		patient.provisional_diagnosis,
		ApplicationController.helpers.datetime(patient.confirmation_date),
		patient.other_diagnosed_fever,
		patient.patient_status,
		patient.patient_condition,
		patient.patient_outcome,
		patient.admission_date.try(:strftime, "%d/%m/%Y"),
		patient.death_date.try(:strftime, "%d/%m/%Y"),
		patient.discharge_date.try(:strftime, "%d/%m/%Y"),
		(patient.reporting_date? ? ApplicationController.helpers.date(patient.reporting_date) : nil),
		patient.entered_by,
		(patient.from_lab.try(:username) || patient.user.try(:username)),
		(patient.lab_name.present? ? patient.lab_name : patient.try(:lab_patient).try(:lab).try(:lab_name)),
		ns1,
		pcr,
		igg,
		igm,
		lab_result.present? ? lab_result.advised_test.try(:join, ",") : 'N/A',
		lab_result.present? ? (lab_result.report_ordering_date.try(:strftime, "on %m/%d/%Y at %I:%M%p")) : 'N/A',
		lab_result.present? ? (lab_result.report_receiving_date.try(:strftime, "on %m/%d/%Y at %I:%M%p")) : 'N/A',
		lab_turnaround_time,
		cbc_report_order_date_first,
		cbc_report_receiving_date_first,
		cbc_report_order_date_second,
		cbc_report_receiving_date_second,
		cbc_report_order_date_third,
		cbc_report_receiving_date_third,
		cbc_turnaround_first,
		cbc_turnaround_second,
		cbc_turnaround_third,
    dengue_virus_type,
    patient.death_review_status,

	hct_first_reading,
	hct_first_reading_date,
	wbc_first_reading,
	wbc_first_reading_date,
	platelet_first_reading,
	platelet_first_reading_date,

	diagnosis,
	diagnosis_change_date.try(:strftime, "on %m/%d/%Y at %I:%M%p"),
	patient.try(:admitted_hospital).try(:category),
	patient.try(:admitted_hospital).try(:facility_type),
	patient.travel_history || 'NA'
	]
	end

	def self.diagnosis_change_log_csv(current_user, q)
		patient_lab_tests_headers = ["Sr No.", "Province", "District", "Hospital", "Facility Type", "Patient ID", "Patient Name", "Suspected", "Probable", "Confirmed", "Non-Dengue"]
		CSV.generate(headers: true) do |csv|
			csv << patient_lab_tests_headers
			@patients = Patient.find_by_sql(q)
			@patients.each_with_index do |patient, i|
				patient_row = self.diagnosis_change_log_data(i, patient)
				csv << patient_row
			end
		end
	end

	def self.lab_diagnosis_change_log_csv(current_user, q)
		lab_result_patient_lab_tests_headers = ["Sr No.", "District", "Hospital", "Patient ID", "Patient Name","Entry Date" ,"Dengue Fever", "Dengue Hemorrhagic Fever", "DSS(Dengue Shock Syndrome)", "Other"]
		CSV.generate(headers: true) do |csv|
			csv << lab_result_patient_lab_tests_headers
			@patients = Patient.find_by_sql(q)
			@patients.each_with_index do |patient, i|
				patient_row = self.lab_diagnosis_change_log_data(i, patient)
				csv << patient_row
			end
		end
	end


	def self.lab_diagnosis_change_log_data(i, patient)
		return [i+1, patient.district, patient.hospital, patient.patient_id, patient.patient_name,patient.entry_date, patient.df ||= '-', patient.dhf ||= '-', patient.dss ||= '-', patient.other ||= '-']
	end


	def self.diagnosis_change_log_data(i, patient)
		return [i+1, patient.province_name, patient.district, patient.hospital, patient.facility_type, patient.patient_id, patient.patient_name, patient.suspected ||= '-', patient.probable ||= '-', patient.confirmed ||= '-', patient.non_dengue ||= '-']
	end

	def self.audit_trail_query(params)
		# patient_id_params_auditable = params[:pid].present? ? "A.auditable_id = '#{params[:pid]}'" : "true"
		# patient_id_params_associated = params[:pid].present? ? "A.associated_id = '#{params[:pid]}'" : "true"
		# q_p_id = true
		# q_dates = true
		# q_p_id = "p.id = '#{params[:pid]}'" if params[:pid].present?
		# q_dates = "A.created_at between '#{params[:datefrom]}' and '#{params[:dateto]}'" if (params[:datefrom].present? and params[:dateto].present?)
		# <<-SQL
		# SELECT
		# CASE
        # 	WHEN P.id IS NOT NULL THEN P.id
        # 	ELSE A.ASSOCIATED_ID
    	# END AS patient_id,

		# (A.AUDITED_changes -> 'patient_name' ->>0) as opname,
		# (A.AUDITED_changes -> 'patient_name' ->>1) as npname,
		# (A.AUDITED_changes -> 'cnic' ->>0) as ocnic,
		# (A.AUDITED_changes -> 'cnic' ->>1) as ncnic,
		# (A.AUDITED_changes -> 'patient_contact' ->>0) as opcont_num,
		# (A.AUDITED_changes -> 'patient_contact' ->>1) as npcont_num,
		# (A.AUDITED_changes -> 'address' ->>0) as oaddress,
		# (A.AUDITED_changes -> 'address' ->>1) as naddress,
		# (A.AUDITED_changes -> 'permanent_address' ->>0) as o_p_address,
		# (A.AUDITED_changes -> 'permanent_address' ->>1) as n_p_address,
		# (A.AUDITED_changes -> 'workplace_address' ->>0) as o_w_address,
		# (A.AUDITED_changes -> 'workplace_address' ->>1) as n_w_address,
		# D1.DISTRICT_NAME AS odist,
		# D2.DISTRICT_NAME AS ndist,
		# D3.DISTRICT_NAME AS o_p_dist,
		# D4.DISTRICT_NAME AS n_p_dist,
		# D5.DISTRICT_NAME AS o_w_dist,
		# D6.DISTRICT_NAME AS n_w_dist,
		# TEH1.TEHSIL_NAME AS oteh,
		# TEH2.TEHSIL_NAME AS nteh,
		# TEH3.TEHSIL_NAME AS o_p_teh,
		# TEH4.TEHSIL_NAME AS n_p_teh,
		# TEH5.TEHSIL_NAME AS o_w_teh,
		# TEH6.TEHSIL_NAME AS n_w_teh,
		# CASE
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 0 THEN 'Non-Dengue'
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 1 THEN 'Probable'
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 2 THEN 'Suspected'
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 3 THEN 'Confirmed'
		# END AS opv,
		# CASE
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 0 THEN 'Non-Dengue'
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 1 THEN 'Probable'
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 2 THEN 'Suspected'
		# 	WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 3 THEN 'Confirmed'
		# END AS npv,
		# CASE
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 0 THEN 'Admitted'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 1 THEN 'Death'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 2 THEN 'Discharged'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 3 THEN 'LAMA'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 4 THEN 'Outpatient'
		# END AS opoutcome,
		# CASE
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 0 THEN 'Admitted'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 1 THEN 'Death'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 2 THEN 'Discharged'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 3 THEN 'LAMA'
		# 	WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 4 THEN 'Outpatient'
		# END AS npoutcome,
		# (A.AUDITED_changes -> 'admission_date' ->>0) as oadmission_date,
		# (A.AUDITED_changes -> 'admission_date' ->>1) as nadmission_date,
		# (A.AUDITED_changes -> 'death_date' ->>0) as odeath_date,
		# (A.AUDITED_changes -> 'death_date' ->>1) as ndeath_date,
		# (A.AUDITED_changes -> 'discharge_date' ->>0) as odischarge_date,
		# (A.AUDITED_changes -> 'discharge_date' ->>1) as ndischarge_date,
		# (A.AUDITED_changes -> 'lama_date' ->>0) as olama_date,
		# (A.AUDITED_changes -> 'lama_date' ->>1) as nlama_date,

		# (A.AUDITED_changes -> 'diagnosis' ->>0) as old_diagnosis,
		# (A.AUDITED_changes -> 'diagnosis' ->>1) as new_diagnosis,
		# (A.AUDITED_changes -> 'diagnosis_change_date' ->>0) as old_diagnosis_change_date,
		# (A.AUDITED_changes -> 'diagnosis_change_date' ->>1) as new_diagnosis_change_date,
		# (A.AUDITED_changes -> 'ns1' ->>0) as old_ns1,
		# (A.AUDITED_changes -> 'ns1' ->>1) as new_ns1,
		# (A.AUDITED_changes -> 'pcr' ->>0) as old_pcr,
		# (A.AUDITED_changes -> 'pcr' ->>1) as new_pcr,
		# (A.AUDITED_changes -> 'igg' ->>0) as old_igg,
		# (A.AUDITED_changes -> 'igg' ->>1) as new_igg,
		# (A.AUDITED_changes -> 'igm' ->>0) as old_igm,
		# (A.AUDITED_changes -> 'igm' ->>1) as new_igm,
		# (A.AUDITED_changes -> 'dengue_virus_type' ->>0) as old_dengue_virus_type,
		# (A.AUDITED_changes -> 'dengue_virus_type' ->>1) as new_dengue_virus_type,
		# A.ACTION,
		# A.CREATED_AT as changed_at,
		# UU.USERNAME AS changed_by
		# FROM Patients P
		# RIGHT JOIN AUDITS A ON A.AUDITABLE_ID = P.ID
		# INNER JOIN USERS UU ON A.USER_ID = UU.ID
		# LEFT JOIN DISTRICTS D1 ON D1.ID = (A.AUDITED_CHANGES -> 'district_id' ->> 0)::integer
		# LEFT JOIN DISTRICTS D2 ON D2.ID = (A.AUDITED_CHANGES -> 'district_id' ->> 1)::integer
		# LEFT JOIN DISTRICTS D3 ON D3.ID = (A.AUDITED_CHANGES -> 'permanent_district_id' ->> 0)::integer
		# LEFT JOIN DISTRICTS D4 ON D4.ID = (A.AUDITED_CHANGES -> 'permanent_district_id' ->> 1)::integer
		# LEFT JOIN DISTRICTS D5 ON D5.ID = (A.AUDITED_CHANGES -> 'workplace_district_id' ->> 0)::integer
		# LEFT JOIN DISTRICTS D6 ON D6.ID = (A.AUDITED_CHANGES -> 'workplace_district_id' ->> 1)::integer
		# LEFT JOIN TEHSILS TEH1 ON TEH1.ID = (A.AUDITED_CHANGES -> 'tehsil_id' ->> 0)::integer
		# LEFT JOIN TEHSILS TEH2 ON TEH2.ID = (A.AUDITED_CHANGES -> 'tehsil_id' ->> 1)::integer
		# LEFT JOIN TEHSILS TEH3 ON TEH3.ID = (A.AUDITED_CHANGES -> 'permanent_tehsil_id' ->> 0)::integer
		# LEFT JOIN TEHSILS TEH4 ON TEH4.ID = (A.AUDITED_CHANGES -> 'permanent_tehsil_id' ->> 1)::integer
		# LEFT JOIN TEHSILS TEH5 ON TEH5.ID = (A.AUDITED_CHANGES -> 'workplace_tehsil_id' ->> 0)::integer
		# LEFT JOIN TEHSILS TEH6 ON TEH6.ID = (A.AUDITED_CHANGES -> 'workplace_tehsil_id' ->> 1)::integer
		# WHERE (A.auditable_type = 'Patient'
		# 	AND #{patient_id_params_auditable} OR A.associated_type = 'Patient' AND #{patient_id_params_associated})
		# AND #{q_dates}
		# ORDER BY A.AUDITABLE_ID DESC, A.CREATED_AT desc
		# SQL







		












		patient_id_params_auditable = params[:pid].present? ? "A.auditable_id = '#{params[:pid]}'" : "true"
		patient_id_params_associated = params[:pid].present? ? "A.associated_id = '#{params[:pid]}'" : "true"
		q_p_id = true
		q_dates = true
		q_p_id = "p.id = '#{params[:pid]}'" if params[:pid].present?
		q_dates = "A.created_at between '#{params[:datefrom]}' and '#{params[:dateto]}'" if (params[:datefrom].present? and params[:dateto].present?)
		<<-SQL
		SELECT
		CASE
        	WHEN P.id IS NOT NULL THEN P.id
        	ELSE A.ASSOCIATED_ID
    	END AS patient_id,

		(A.AUDITED_changes -> 'patient_name' ->>0) as opname,
		(A.AUDITED_changes -> 'patient_name' ->>1) as npname,
		(A.AUDITED_changes -> 'cnic' ->>0) as ocnic,
		(A.AUDITED_changes -> 'cnic' ->>1) as ncnic,
		(A.AUDITED_changes -> 'patient_contact' ->>0) as opcont_num,
		(A.AUDITED_changes -> 'patient_contact' ->>1) as npcont_num,
		(A.AUDITED_changes -> 'address' ->>0) as oaddress,
		(A.AUDITED_changes -> 'address' ->>1) as naddress,
		(A.AUDITED_changes -> 'permanent_address' ->>0) as o_p_address,
		(A.AUDITED_changes -> 'permanent_address' ->>1) as n_p_address,
		(A.AUDITED_changes -> 'workplace_address' ->>0) as o_w_address,
		(A.AUDITED_changes -> 'workplace_address' ->>1) as n_w_address,
		(A.AUDITED_changes -> 'district' ->>0) as odist,
		(A.AUDITED_changes -> 'district' ->>1) AS ndist,
		(A.AUDITED_changes -> 'permanent_district' ->>0) AS o_p_dist,
		(A.AUDITED_changes -> 'permanent_district' ->>1) AS n_p_dist,
		(A.AUDITED_changes -> 'workplace_district' ->>0) AS o_w_dist,
		(A.AUDITED_changes -> 'workplace_district' ->>1) AS n_w_dist,
		(A.AUDITED_changes -> 'tehsil' ->>0) AS oteh,
		(A.AUDITED_changes -> 'tehsil' ->>1) AS nteh,
		(A.AUDITED_changes -> 'permanent_tehsil' ->>0) AS o_p_teh,
		(A.AUDITED_changes -> 'permanent_tehsil' ->>1) AS n_p_teh,
		(A.AUDITED_changes -> 'workplace_tehsil' ->>0) AS o_w_teh,
		(A.AUDITED_changes -> 'workplace_tehsil' ->>1) AS n_w_teh,
		CASE
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 0 THEN 'Non-Dengue'
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 1 THEN 'Probable'
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 2 THEN 'Suspected'
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 0)::integer = 3 THEN 'Confirmed'
		END AS opv,
		CASE
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 0 THEN 'Non-Dengue'
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 1 THEN 'Probable'
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 2 THEN 'Suspected'
			WHEN (A.AUDITED_changes -> 'provisional_diagnosis' ->> 1)::integer = 3 THEN 'Confirmed'
		END AS npv,
		CASE
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 0 THEN 'Admitted'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 1 THEN 'Death'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 2 THEN 'Discharged'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 3 THEN 'LAMA'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 0)::integer = 4 THEN 'Outpatient'
		END AS opoutcome,
		CASE
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 0 THEN 'Admitted'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 1 THEN 'Death'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 2 THEN 'Discharged'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 3 THEN 'LAMA'
			WHEN (A.AUDITED_changes -> 'patient_outcome' ->> 1)::integer = 4 THEN 'Outpatient'
		END AS npoutcome,
		(A.AUDITED_changes -> 'admission_date' ->>0) as oadmission_date,
		(A.AUDITED_changes -> 'admission_date' ->>1) as nadmission_date,
		(A.AUDITED_changes -> 'death_date' ->>0) as odeath_date,
		(A.AUDITED_changes -> 'death_date' ->>1) as ndeath_date,
		(A.AUDITED_changes -> 'discharge_date' ->>0) as odischarge_date,
		(A.AUDITED_changes -> 'discharge_date' ->>1) as ndischarge_date,
		(A.AUDITED_changes -> 'lama_date' ->>0) as olama_date,
		(A.AUDITED_changes -> 'lama_date' ->>1) as nlama_date,

		(A.AUDITED_changes -> 'diagnosis' ->>0) as old_diagnosis,
		(A.AUDITED_changes -> 'diagnosis' ->>1) as new_diagnosis,
		(A.AUDITED_changes -> 'diagnosis_change_date' ->>0) as old_diagnosis_change_date,
		(A.AUDITED_changes -> 'diagnosis_change_date' ->>1) as new_diagnosis_change_date,
		(A.AUDITED_changes -> 'ns1' ->>0) as old_ns1,
		(A.AUDITED_changes -> 'ns1' ->>1) as new_ns1,
		(A.AUDITED_changes -> 'pcr' ->>0) as old_pcr,
		(A.AUDITED_changes -> 'pcr' ->>1) as new_pcr,
		(A.AUDITED_changes -> 'igg' ->>0) as old_igg,
		(A.AUDITED_changes -> 'igg' ->>1) as new_igg,
		(A.AUDITED_changes -> 'igm' ->>0) as old_igm,
		(A.AUDITED_changes -> 'igm' ->>1) as new_igm,
		(A.AUDITED_changes -> 'dengue_virus_type' ->>0) as old_dengue_virus_type,
		(A.AUDITED_changes -> 'dengue_virus_type' ->>1) as new_dengue_virus_type,
		A.ACTION,
		A.CREATED_AT as changed_at,
		UU.USERNAME AS changed_by
		FROM Patients P
		RIGHT JOIN AUDITS A ON A.AUDITABLE_ID = P.ID
		INNER JOIN USERS UU ON A.USER_ID = UU.ID
		WHERE (A.auditable_type = 'Patient'
			AND #{patient_id_params_auditable} OR A.associated_type = 'Patient' AND #{patient_id_params_associated})
		AND #{q_dates}
		ORDER BY A.CREATED_AT desc
		SQL
	end
end