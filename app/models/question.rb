class Question < ApplicationRecord
  has_many :answers, dependent: :destroy

  validates :item, presence: true, uniqueness: true
  validates :question_text, presence: true
  validates :option_a, :option_b, :option_c, :option_d, presence: true
  validates :correct_answer, presence: true, inclusion: { in: %w[a b c d] }

  def self.random_sample
    order("RANDOM()").limit(30)
  end
end
