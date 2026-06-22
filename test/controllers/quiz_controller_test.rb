require "test_helper"

class QuizControllerTest < ActionDispatch::IntegrationTest
  test "GET / renders landing" do
    get root_path
    assert_response :success
  end

  test "POST /start creates student and attempt, redirects to quiz" do
    post start_quiz_path, params: { cedula: "99999", name: "Test User", email: "test@test.com", zona: "Piedemonte", policy_accepted: "1" }
    assert_redirected_to quiz_path

    student = Student.find_by(cedula: "99999")
    assert_not_nil student
    assert_equal 1, student.attempts.count
    assert_equal "Piedemonte", student.zona
  end

  test "POST /start blocks if already has 1 attempt" do
    student = Student.create!(cedula: "88888", name: "Blocked", email: "blocked@test.com", zona: "Castilla", attempts_count: 1)

    post start_quiz_path, params: { cedula: student.cedula, name: student.name, email: student.email, zona: "Castilla", policy_accepted: "1" }
    assert_redirected_to root_path
    follow_redirect!
    assert_match /máximo de intentos/, response.body
  end

  test "POST /start with blank fields redirects with error" do
    post start_quiz_path, params: { cedula: "", name: "Test", email: "test@test.com", zona: "Piedemonte", policy_accepted: "1" }
    assert_redirected_to root_path
  end

  test "POST /start without zona redirects with error" do
    post start_quiz_path, params: { cedula: "12345", name: "Test", email: "test@test.com" }
    assert_redirected_to root_path
  end

  test "GET /quiz redirects without active attempt" do
    get quiz_path
    assert_redirected_to root_path
  end

  test "GET /quiz shows 5 questions per page" do
    post start_quiz_path, params: { cedula: "123456789", name: "Quiz Test", email: "quiz1@test.com", zona: "Neiva", policy_accepted: "1" }
    follow_redirect!
    assert_response :success
    assert_select "input[type=radio]", count: 20
  end

  test "GET /quiz redirects to submit if expired" do
    post start_quiz_path, params: { cedula: "777777", name: "Expired", email: "expired@test.com", zona: "Tibu", policy_accepted: "1" }
    follow_redirect!

    student = Student.find_by(cedula: "777777")
    attempt = student.attempts.find_by(status: "in_progress")
    attempt.update!(started_at: 25.minutes.ago)

    get quiz_path
    assert_redirected_to submit_quiz_path(auto_submit: true)
  end

  test "POST /submit with all 30 answers completes and redirects" do
    post start_quiz_path, params: { cedula: "987654321", name: "Full Test", email: "full@test.com", zona: "Rubiales", policy_accepted: "1" }
    follow_redirect!

    student = Student.find_by(cedula: "987654321")
    attempt = student.attempts.find_by(status: "in_progress")
    question_ids = Question.random_sample.pluck(:id)

    answers_params = question_ids.to_h { |id| [ id.to_s, "a" ] }

    post submit_quiz_path, params: { answers: answers_params }
    assert_redirected_to results_path(attempt)
  end

  test "POST /submit accepts partial answers if expired" do
    post start_quiz_path, params: { cedula: "666666", name: "Partial", email: "partial@test.com", zona: "CP9", policy_accepted: "1" }
    follow_redirect!

    student = Student.find_by(cedula: "666666")
    attempt = student.attempts.find_by(status: "in_progress")
    attempt.update!(started_at: 25.minutes.ago)

    question_ids = Question.random_sample.pluck(:id)
    partial_answers = question_ids.first(10).to_h { |id| [ id.to_s, "a" ] }

    post submit_quiz_path, params: { answers: partial_answers, auto_submit: "true" }
    assert_redirected_to results_path(attempt)

    attempt.reload
    assert_equal "completed", attempt.status
    assert_equal 10, attempt.answers.count
  end

  test "POST /submit rejects completed attempt" do
    post start_quiz_path, params: { cedula: "555666777", name: "Double", email: "double@test.com", zona: "Apiay", policy_accepted: "1" }
    follow_redirect!

    student = Student.find_by(cedula: "555666777")
    attempt = student.attempts.find_by(status: "in_progress")
    question_ids = Question.random_sample.pluck(:id)

    answers_params = question_ids.to_h { |id| [ id.to_s, "a" ] }

    post submit_quiz_path, params: { answers: answers_params }
    assert_redirected_to results_path(attempt)

    follow_redirect!
    assert_response :success

    post submit_quiz_path, params: { answers: answers_params }
    assert_redirected_to results_path(attempt)
  end

  test "GET /results shows score for valid attempt" do
    post start_quiz_path, params: { cedula: "111222333", name: "Results", email: "results@test.com", zona: "Provincia", policy_accepted: "1" }
    follow_redirect!

    student = Student.find_by(cedula: "111222333")
    attempt = student.attempts.find_by(status: "in_progress")
    question_ids = Question.random_sample.pluck(:id)

    answers_params = question_ids.to_h { |id| [ id.to_s, Question.find(id).correct_answer ] }

    post submit_quiz_path, params: { answers: answers_params }
    follow_redirect!

    assert_response :success
    assert_match /"fs-1 fw-bold">30</, response.body
    assert_match /de 30/, response.body
  end

  test "GET /results for non-existent attempt redirects" do
    get results_path(999999)
    assert_redirected_to root_path
  end

  test "GET /results passes weak_topics to view" do
    post start_quiz_path, params: { cedula: "222333444", name: "Weak Topics", email: "weak@test.com", zona: "Nare", policy_accepted: "1" }
    follow_redirect!

    student = Student.find_by(cedula: "222333444")
    attempt = student.attempts.find_by(status: "in_progress")
    question_ids = Question.random_sample.pluck(:id)

    answers_params = question_ids.to_h { |id| [ id.to_s, "a" ] }

    post submit_quiz_path, params: { answers: answers_params }
    follow_redirect!

    assert_response :success
  end
end
