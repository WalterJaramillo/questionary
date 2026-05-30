require "test_helper"

class StudentTest < ActiveSupport::TestCase
  test "can_take_quiz? returns true with 0 attempts" do
    student = students(:alice)
    assert student.can_take_quiz?
  end

  test "can_take_quiz? returns true with 1 attempt" do
    student = students(:charlie)
    assert_equal 1, student.attempts_count
    assert student.can_take_quiz?
  end

  test "can_take_quiz? returns false with 2 attempts" do
    student = students(:bob)
    assert_equal 2, student.attempts_count
    assert_not student.can_take_quiz?
  end

  test "validates presence of required fields" do
    student = Student.new
    assert_not student.valid?
    assert_includes student.errors[:cedula], "can't be blank"
    assert_includes student.errors[:name], "can't be blank"
    assert_includes student.errors[:email], "can't be blank"
  end

  test "validates cedula uniqueness" do
    duplicate = Student.new(
      cedula: students(:alice).cedula,
      name: "Other",
      email: "other@test.com"
    )
    assert_not duplicate.valid?
  end

  test "attempts_count defaults to 0" do
    student = Student.new(
      cedula: "new_cedula",
      name: "New",
      email: "new@test.com"
    )
    assert_equal 0, student.attempts_count
  end
end
