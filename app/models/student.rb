class Student < ApplicationRecord
  MAX_ATTEMPTS = 2

  has_many :attempts, dependent: :destroy

  validates :cedula, presence: true, uniqueness: true, format: { with: /\A\d+\z/, message: "solo puede contener números" }
  validates :name, presence: true
  validates :email, presence: true

  def can_take_quiz?
    attempts_count < MAX_ATTEMPTS
  end

  def latest_in_progress_attempt
    attempts.where(status: "in_progress").last
  end
end
