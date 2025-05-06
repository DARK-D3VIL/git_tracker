class Review < ApplicationRecord
  validates :review_id, presence: true
  belongs_to :pull_request, foreign_key: :pr_id, primary_key: :pr_id
  belongs_to :employee, foreign_key: :github_id, primary_key: :github_id
end
