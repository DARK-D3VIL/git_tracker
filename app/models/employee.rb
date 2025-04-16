class Employee < ApplicationRecord
  has_many :developer_matrices, foreign_key: :github_id
  has_many :reviews, foreign_key: :github_id
end