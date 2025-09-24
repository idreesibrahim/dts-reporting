module ActivitiesHelper
  def is_bogus_activities?
    current_page?(controller: 'surveillance', action: 'simple_activity_line_list') == true or current_page?(controller: 'simples', action: 'bogus_activities') == true
  end
end
