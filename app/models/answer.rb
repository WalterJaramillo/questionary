class Answer < ApplicationRecord
  belongs_to :attempt
  belongs_to :question

  validates :selected_option, presence: true, inclusion: { in: %w[a b c d] }
  validates :attempt_id, uniqueness: { scope: :question_id }
end
