module SharedCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :update_railway_colony_to_baja_line
  end

  private

  def update_railway_colony_to_baja_line
		if self.uc_name.present?
			if self.uc_name.downcase == 'baja line'
				self.uc_name = "Railway Colony"
			end
		end
	end
end
