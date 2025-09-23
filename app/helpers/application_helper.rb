module ApplicationHelper
	def per_page_items(items = 1000000)
		  (params[:pagination] == "No" or request.format == "xls") ? items : 20
	end
	def patient_tag_list
		  tags = []
		  if current_user.department_user?
			  tags = Tag.joins(:departments).where("departments.id = ?",current_user.department_id).order("tag_name").collect{|tag| [tag.tag_name, tag.id]}
		  else
			  tags = Tag.where("m_category_id = ?", 2).order("tag_name").collect{|tag| [tag.tag_name, tag.id]}

		  end
		  return tags
	end

	def non_patient_tag_list
		  tags = []
		  if current_user.department_user?
			  tags = Tag.joins(:departments).where("departments.id = ?",current_user.department_id).order("tag_name").collect{|tag| [tag.tag_name, tag.id]}
		  else
		  tags = Tag.where("m_category_id != ?",2).order("tag_name").collect{|tag| [tag.tag_name, tag.id]}
		  end
		  return tags
	end
	def new_departments_list
		  departments = []
		  q_parent_department = params[:parent_department].present? ? "departments.parent_department_id = '#{params[:parent_department]}'" : true
		departments = Department.accessible_by(current_ability).where("#{q_parent_department}").order("new_dep_name").collect { | dep | [dep.new_dep_name, dep.id] }
		return departments
	end
	def all_districts_punjab
		  districts = District.select('id, district_name').accessible_by(current_ability).punjab.order('district_name asc').collect { | dist | [dist.district_name, dist.id] }
			return districts
	end
	def tehsil_information(district)
		  district =  current_user.district_id if current_user.district_user?
		  district_q = district.present? ? "district_id = '#{district}'" : 1==2
		  tehsils = Tehsil.accessible_by(current_ability).select('id, tehsil_name').where("#{district_q}").order('tehsil_name').collect { | teh | [teh.tehsil_name, teh.id] }
		  return tehsils
	end
	def ucs_information(tehsil)
		  tehsil_q  = tehsil.present? ? "tehsil_id = '#{tehsil}'" : 1 == 2
		  ucs = Uc.select("id,uc_name").where("#{tehsil_q}").collect { | uc | [uc.uc_name, uc.id] }
		  return ucs
	end
	def max_date_today
			Time.now.end_of_day.strftime('%Y-%m-%dT%H:%M')
	end
	def get_yesno(x)
		  return x = nil if x.nil? || x == ''
		  return x == true ? 'Yes' : 'No'
	end
	def merge_username_and_name(activity)
		if activity.user.present?
			if activity.user.name.present?
				if params[:format].present?
					"#{activity.user.username}(#{activity.user.name})".html_safe
				else
					"#{activity.user.username}<br>#{activity.user.name}".html_safe
				end
			end
		end
	end
end
