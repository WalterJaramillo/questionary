require "test_helper"

class AttemptTest < ActiveSupport::TestCase
  test "complete! calculates score correctly" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)

    questions = Question.limit(3).to_a
    answers_params = {
      questions[0].id.to_s => questions[0].correct_answer,
      questions[1].id.to_s => %w[a b c d].reject { |l| l == questions[1].correct_answer }.first,
      questions[2].id.to_s => questions[2].correct_answer
    }

    attempt.complete!(answers_params)

    assert_equal "completed", attempt.status
    assert_equal 2, attempt.score
    assert_not_nil attempt.completed_at
  end

  test "complete! increments student attempts_count" do
    student = students(:alice)
    original_count = student.attempts_count
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)

    questions = Question.limit(1).to_a
    answers_params = { questions[0].id.to_s => "a" }
    attempt.complete!(answers_params)

    student.reload
    assert_equal original_count + 1, student.attempts_count
  end

  test "complete! raises if already completed" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "completed", started_at: Time.current, completed_at: Time.current, score: 0)

    questions = Question.limit(1).to_a
    answers_params = { questions[0].id.to_s => "a" }

    assert_raises(StandardError) do
      attempt.complete!(answers_params)
    end
  end

  test "completed? returns correct boolean" do
    student = students(:alice)
    in_progress = student.attempts.create!(status: "in_progress", started_at: Time.current)
    completed = student.attempts.create!(status: "completed", started_at: Time.current, completed_at: Time.current, score: 0)

    assert_not in_progress.completed?
    assert completed.completed?
  end
end
