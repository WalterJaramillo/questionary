require "test_helper"

class QuizControllerTest < ActionDispatch::IntegrationTest
  test "GET / renders landing" do
    get root_path
    assert_response :success
  end

  test "POST /start creates student and attempt, redirects to quiz" do
    post start_quiz_path, params: { cedula: "99999", name: "Test User", email: "test@test.com" }
    assert_redirected_to quiz_path

    student = Student.find_by(cedula: "99999")
    assert_not_nil student
    assert_equal 1, student.attempts.count
  end

  test "POST /start blocks at max attempts" do
    student = students(:bob)
    assert_equal 2, student.attempts_count

    post start_quiz_path, params: { cedula: student.cedula, name: student.name, email: student.email }
    assert_response :unprocessable_entity
    assert_match /máximo de intentos/, response.body
  end

  test "POST /start with blank fields shows error" do
    post start_quiz_path, params: { cedula: "", name: "Test", email: "test@test.com" }
    assert_response :unprocessable_entity
    assert_match /obligatorios/, response.body
  end

  test "GET /quiz redirects without active attempt" do
    get quiz_path
    assert_redirected_to root_path
  end

  test "GET /quiz shows 5 questions per page" do
    post start_quiz_path, params: { cedula: "123456789", name: "Quiz Test", email: "quiz1@test.com" }
    follow_redirect!
    assert_response :success
    assert_select "input[type=radio]", count: 20
  end

  test "POST /submit with all 30 answers completes and redirects" do
    post start_quiz_path, params: { cedula: "987654321", name: "Full Test", email: "full@test.com" }
    follow_redirect!

    student = Student.find_by(cedula: "987654321")
    attempt = student.attempts.find_by(status: "in_progress")
    question_ids = Question.random_sample.pluck(:id)

    answers_params = question_ids.to_h { |id| [id.to_s, "a"] }

    post submit_quiz_path, params: { answers: answers_params }
    assert_redirected_to results_path(attempt)
  end

  test "POST /submit rejects completed attempt" do
    post start_quiz_path, params: { cedula: "555666777", name: "Double", email: "double@test.com" }
    follow_redirect!

    student = Student.find_by(cedula: "555666777")
    attempt = student.attempts.find_by(status: "in_progress")
    question_ids = Question.random_sample.pluck(:id)

    answers_params = question_ids.to_h { |id| [id.to_s, "a"] }

    post submit_quiz_path, params: { answers: answers_params }
    assert_redirected_to results_path(attempt)

    follow_redirect!
    assert_response :success

    post submit_quiz_path, params: { answers: answers_params }
    assert_redirected_to results_path(attempt)
  end

  test "GET /results shows score for valid attempt" do
    post start_quiz_path, params: { cedula: "111222333", name: "Results", email: "results@test.com" }
    follow_redirect!

    student = Student.find_by(cedula: "111222333")
    attempt = student.attempts.find_by(status: "in_progress")
    question_ids = Question.random_sample.pluck(:id)

    answers_params = question_ids.to_h { |id| [id.to_s, Question.find(id).correct_answer] }

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
end
