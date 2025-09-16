class Mv::ConsolidateTpvReport < ApplicationRecord
  self.table_name = "consolidate_tpv_report"
  include TpvJobActivityFilterable
  include ActionView::Helpers::NumberHelper
  ## scops
  scope :filter_by_type, ->(data){data.present? ? where("consolidate_tpv_report.filter_type =?", data) : where("true")}
  scope :filter_by_district_id, ->(data){data.present? ? where("consolidate_tpv_report.district_id =?", data) : where("true")}
  scope :filter_by_tehsil_id, ->(data){data.present? ? where("consolidate_tpv_report.tehsil_id =?", data) : where("true")}
  scope :filter_by_uc_id, ->(data){data.present? ? where("consolidate_tpv_report.uc_id =?", data) : where("true")}
  scope :filter_by_dep_category_id, ->(data){data.present? ? where("consolidate_tpv_report.dep_category_id =?", data) : where("true")}
  scope :filter_by_tpv_datefrom, ->(data){data.present? ? (where("consolidate_tpv_report.tpv_job_activity_expire_at >= ?", Time.parse("#{data}").to_datetime.beginning_of_day) ) : where("true")}
	scope :filter_by_tpv_dateto, ->(data){data.present? ? (where("consolidate_tpv_report.tpv_job_activity_expire_at <= ?", Time.parse("#{data}").to_datetime.end_of_day) ) : where("true")}


  ## partial methods
  def performance_rate
    number = ((attempted_codes.to_f/total_codes_generated.to_f)*100).to_f
    number = 0 if number.infinite?
    convert_two_decimal(number)
  end
  def convert_two_decimal(price)
    number_with_precision(price, precision: 2)
  end
  # private
  def self.to_csv
    tpv_headers = ["Sr No.", "Codes Expired Date", "District", "Town", "UC", "Department Category", "Total Codes Generated", "Attempted Codes", "Unattempted Codes", "Dormant Auditor Users", "Active Audit Users", "Performance Rate"]
		CSV.generate(headers: true) do |csv|
			csv << tpv_headers
      all.each_with_index do |data, i|
        tpv_row =
        [
          i+1,
          data.tpv_job_activity_expire_at,
          data.district_name,
          data.tehsil_name,
          data.uc_name,
          data.dep_category,
          data.total_codes_generated,
          data.attempted_codes,
          data.unattempted_codes,
          data.dormant_auditor_users,
          data.active_audit_users,
          data.performance_rate
        ]
        csv << tpv_row
      end
		end
  end
end
