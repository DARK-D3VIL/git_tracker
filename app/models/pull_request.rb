class PullRequest < ApplicationRecord
  validates :pr_id, presence: true, uniqueness: true
  has_many :reviews, foreign_key: :pr_id
  has_many :developer_matrices, foreign_key: :pr_id
end
