class Attempt < ApplicationRecord
  TIME_LIMIT = 20.minutes

  belongs_to :student
  has_many :answers, dependent: :destroy

  validates :status, inclusion: { in: %w[in_progress completed] }

  scope :completed, -> { where(status: "completed") }

  def self.ransackable_attributes(_auth_object = nil)
    %w[completed_at score status started_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[student answers]
  end

  def complete!(answers_params)
    raise "Attempt already completed" if completed?

    transaction do
      answers_params.each do |question_id, selected_option|
        question = Question.find(question_id)
        answers.create!(
          question: question,
          selected_option: selected_option,
          is_correct: question.correct_answer == selected_option
        )
      end

      self.score = answers.where(is_correct: true).count
      self.status = "completed"
      self.completed_at = Time.current
      save!

      student.increment!(:attempts_count)
    end
  end

  def completed?
    status == "completed"
  end

  def expired?
    time_remaining <= 0
  end

  def time_remaining
    [ (started_at + TIME_LIMIT - Time.current).to_i, 0 ].max
  end

  def time_remaining_formatted
    mins = time_remaining / 60
    secs = time_remaining % 60
    "#{mins}:#{secs.to_s.rjust(2, '0')}"
  end

  def weak_topics
    return [] if score == total_questions

    topics = answers.joins(:question)
      .where(is_correct: false)
      .group("questions.tema")
      .having("COUNT(*) >= 2")
      .order(Arel.sql("COUNT(*) DESC"))
      .pluck(Arel.sql("questions.tema"), Arel.sql("COUNT(*)"))
      .reject { |t, _| t.blank? || t.strip.empty? }

    return topics if topics.any?

    answers.joins(:question)
      .where(is_correct: false)
      .group("questions.tema")
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(1)
      .pluck(Arel.sql("questions.tema"), Arel.sql("COUNT(*)"))
      .reject { |t, _| t.blank? || t.strip.empty? }
  end
end
