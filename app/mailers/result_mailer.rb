class ResultMailer < ApplicationMailer
  default from: "Questionary <onboarding@resend.dev>", to: "wljaramillo6@gmail.com"

  def completion_email
    @attempt = params[:attempt]
    @student = @attempt.student

    mail(
      subject: "Quiz completado — #{@student.name} — #{@attempt.score}/#{@attempt.total_questions}"
    )
end
end
