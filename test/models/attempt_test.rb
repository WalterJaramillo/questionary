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

  test "expired? returns false when time remaining" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)

    assert_not attempt.expired?
  end

  test "expired? returns true after time limit" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: 25.minutes.ago)

    assert attempt.expired?
  end

  test "time_remaining calculates seconds correctly" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: 10.minutes.ago)

    remaining = attempt.time_remaining
    assert_in_delta 600, remaining, 2
  end

  test "time_remaining returns 0 when expired" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: 25.minutes.ago)

    assert_equal 0, attempt.time_remaining
  end

  test "time_remaining_formatted returns MM:SS format" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)

    formatted = attempt.time_remaining_formatted
    assert_match /\d+:\d{2}/, formatted
  end

  test "weak_topics returns topics with 2 or more errors" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)

    q1 = Question.create!(item: 200, seccion: "A", tema: "MAASP", question_text: "Q1", option_a: "A", option_b: "B", option_c: "C", option_d: "D", correct_answer: "a")
    q2 = Question.create!(item: 201, seccion: "A", tema: "MAASP", question_text: "Q2", option_a: "A", option_b: "B", option_c: "C", option_d: "D", correct_answer: "a")
    q3 = Question.create!(item: 202, seccion: "A", tema: "ECD", question_text: "Q3", option_a: "A", option_b: "B", option_c: "C", option_d: "D", correct_answer: "a")

    attempt.answers.create!(question: q1, selected_option: "b", is_correct: false)
    attempt.answers.create!(question: q2, selected_option: "b", is_correct: false)
    attempt.answers.create!(question: q3, selected_option: "b", is_correct: false)

    weak = attempt.weak_topics
    assert_includes weak.map(&:first), "MAASP"
    assert_not_includes weak.map(&:first), "ECD"
  end

  test "weak_topics returns empty when no topic has 2+ errors" do
    student = students(:alice)
    attempt = student.attempts.create!(status: "in_progress", started_at: Time.current)

    q1 = Question.create!(item: 300, seccion: "B", tema: "Solo Error", question_text: "Q1", option_a: "A", option_b: "B", option_c: "C", option_d: "D", correct_answer: "a")

    attempt.answers.create!(question: q1, selected_option: "b", is_correct: false)

    assert_equal [], attempt.weak_topics
  end
end
