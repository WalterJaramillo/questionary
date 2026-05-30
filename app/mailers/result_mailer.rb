class ResultMailer < ApplicationMailer
  default to: "wljaramillo6@gmail.com"

  def completion_email
    @attempt = params[:attempt]
    @student = @attempt.student

    mail(
      subject: "Quiz completado — #{@student.name} — #{@attempt.score}/#{@attempt.total_questions}",
      from: ENV.fetch("MAILER_FROM", "quiz@questionary.com")
    )
  end
end
