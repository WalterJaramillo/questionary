class Attempt < ApplicationRecord
  belongs_to :student
  has_many :answers, dependent: :destroy

  validates :status, inclusion: { in: %w[in_progress completed] }

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
end
