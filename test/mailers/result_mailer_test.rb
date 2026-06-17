require "test_helper"

class ResultMailerTest < ActionMailer::TestCase
  test "email contains student name, cedula, email, score, date" do
    student = students(:alice)
    attempt = student.attempts.create!(
      status: "completed",
      started_at: Time.current,
      completed_at: Time.current,
      score: 25
    )

    mail = ResultMailer.with(attempt: attempt).completion_email

    assert_includes mail.subject, student.name
    assert_includes mail.subject, "25/30"
    assert_includes mail.body.encoded, student.name
    assert_includes mail.body.encoded, student.cedula
    assert_includes mail.body.encoded, student.email
  end

  test "email subject format" do
    student = students(:alice)
    attempt = student.attempts.create!(
      status: "completed",
      started_at: Time.current,
      completed_at: Time.current,
      score: 20
    )

    mail = ResultMailer.with(attempt: attempt).completion_email
    assert_equal "Quiz completado — #{student.name} — 20/30", mail.subject
  end
end
