class Question < ApplicationRecord
  has_many :answers, dependent: :destroy

  validates :item, presence: true, uniqueness: true
  validates :question_text, presence: true
  validates :option_a, :option_b, :option_c, :option_d, presence: true
  validates :correct_answer, presence: true, inclusion: { in: %w[a b c d] }

  def self.random_sample
    total = 30
    section_counts = group(:seccion).count
    total_questions = count

    allocation = section_counts.map do |seccion, section_total|
      ratio = section_total.to_f / total_questions
      base = (ratio * total).floor
      remainder = (ratio * total) - base
      { seccion: seccion, count: base, remainder: remainder }
    end

    remaining = total - allocation.sum { |a| a[:count] }
    allocation.sort_by { |a| -a[:remainder] }.first(remaining).each { |a| a[:count] += 1 }

    selected = []
    allocation.each do |a|
      selected += where(seccion: a[:seccion]).order("RANDOM()").limit(a[:count])
    end
    selected
  end
end
