require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  test "is_correct is set correctly when matching" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)
    question = questions(:question_1)

    answer = attempt.answers.create!(
      question: question,
      selected_option: question.correct_answer,
      is_correct: true
    )

    assert answer.is_correct
  end

  test "is_correct is set correctly when not matching" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)
    question = questions(:question_1)

    wrong_option = %w[a b c d].reject { |l| l == question.correct_answer }.first
    answer = attempt.answers.create!(
      question: question,
      selected_option: wrong_option,
      is_correct: false
    )

    assert_not answer.is_correct
  end

  test "uniqueness of attempt_id and question_id" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)
    question = questions(:question_1)

    attempt.answers.create!(
      question: question,
      selected_option: "a",
      is_correct: false
    )

    duplicate = attempt.answers.new(
      question: question,
      selected_option: "b",
      is_correct: false
    )

    assert_not duplicate.valid?
  end
end
