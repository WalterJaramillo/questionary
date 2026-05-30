require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "random_sample returns exactly 30 unique questions" do
    questions = Question.random_sample
    assert_equal 30, questions.count
    assert_equal 30, questions.map(&:id).uniq.count
  end

  test "validates presence of required fields" do
    question = Question.new
    assert_not question.valid?
    assert_includes question.errors[:item], "can't be blank"
    assert_includes question.errors[:question_text], "can't be blank"
  end

  test "validates correct_answer is a single letter" do
    question = Question.new(
      item: 999,
      question_text: "Test",
      option_a: "A",
      option_b: "B",
      option_c: "C",
      option_d: "D",
      correct_answer: "x"
    )
    assert_not question.valid?
    assert_includes question.errors[:correct_answer], "is not included in the list"
  end

  test "validates item uniqueness" do
    Question.create!(
      item: 100,
      question_text: "Test",
      option_a: "A",
      option_b: "B",
      option_c: "C",
      option_d: "D",
      correct_answer: "a"
    )
    duplicate = Question.new(
      item: 100,
      question_text: "Test 2",
      option_a: "A",
      option_b: "B",
      option_c: "C",
      option_d: "D",
      correct_answer: "b"
    )
    assert_not duplicate.valid?
  end
end
