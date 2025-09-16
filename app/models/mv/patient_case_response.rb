class Mv::PatientCaseResponse < ApplicationRecord
    self.table_name = 'patient_case_response_view'
    include PatientCaseResponseFilterable

    ## scops
    scope :filter_by_district_id, ->(data){data.present? ? (where("district_id =?", data) ) : where("true")}
    scope :filter_by_pid, ->(data){where("pid =?", data)}
    scope :filter_by_tehsil_id, ->(data){data.present? ? (where("tehsil_id =?", data)) : where("true")}
    scope :filter_by_patient_place, ->(data){where("patient_place =?", data)}
    scope :filter_by_c_date_from, ->(data){where("c_date >= ?", data )}
	scope :filter_by_c_date_to, ->(data){where("c_date <= ?", data )}



    ## CSV
    def self.to_csv(params)
        patient_headers = 
        [   "Sr No.",
            "Patient ID",
            "Patient name",
            "District",
            "Town",
            "Confirmation Date",
            "Start Time",
            "End Time",
            "Duration",
            "Houses Tagged(#{params[:patient_place]})",
            "No. of Users",
            "Users"
        ]
        CSV.generate(headers: true) do |csv|
            csv << patient_headers
            all.each_with_index do |p, i|
                p_row = 
                [
                    i+1,
                    p.pid,
                    p.p_name,
                    p.district,
                    p.tehsil,
                    p.c_date.try(:to_datetime).try(:strftime, "%m/%d/%Y"),
                    p.cr_start_time.try(:to_datetime).try(:strftime, "%m/%d/%Y at %I:%M%p"),
                    p.cr_end_time.try(:to_datetime).try(:strftime, "%m/%d/%Y at %I:%M%p"),
                    p.c_r_duration,
                    p.houses_tagged,
                    p.no_of_users_count,
                    p.c_username
                ]
                csv << p_row
            end
        end
	end

end