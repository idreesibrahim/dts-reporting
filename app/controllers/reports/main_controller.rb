class Reports::MainController < ApplicationController
    before_action :authenticate_user!

    def dormancy_report
    end
end