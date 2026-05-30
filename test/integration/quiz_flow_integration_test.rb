require "test_helper"

class QuizFlowIntegrationTest < ActionDispatch::IntegrationTest
  test "full flow: landing -> start -> quiz -> submit -> results" do
    get root_path
    assert_response :success

    post start_quiz_path, params: { cedula: "444555666", name: "Flow Tester", email: "flow@test.com" }
    assert_redirected_to quiz_path

    follow_redirect!
    assert_response :success
    assert_select "input[type=radio]", count: 20

    student = Student.find_by(cedula: "444555666")
    question_ids = Question.random_sample.pluck(:id)
    answers_params = question_ids.to_h { |id| [id.to_s, Question.find(id).correct_answer] }

    post submit_quiz_path, params: { answers: answers_params }
    assert_redirected_to results_path(student.attempts.find_by(status: "completed"))

    follow_redirect!
    assert_response :success
    assert_match /"fs-1 fw-bold">30</, response.body
  end

  test "second attempt is allowed" do
    student = students(:charlie)
    assert_equal 1, student.attempts_count

    post start_quiz_path, params: { cedula: student.cedula, name: student.name, email: student.email }
    assert_redirected_to quiz_path
  end

  test "third attempt is blocked" do
    student = students(:bob)
    assert_equal 2, student.attempts_count

    post start_quiz_path, params: { cedula: student.cedula, name: student.name, email: student.email }
    assert_response :unprocessable_entity
    assert_match /máximo de intentos/, response.body
  end
end
