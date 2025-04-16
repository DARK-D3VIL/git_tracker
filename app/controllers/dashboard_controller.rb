class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    @developer_matrices = DeveloperMatrix.all
    @employees = Employee.all
    @pull_requests = PullRequest.all
    @reviews = Review.all
  end
end
