class ResultMailer < ApplicationMailer
  default from: "Questionary <onboarding@resend.dev>", to: ["walter.jaramillo51@hotmail.com", "gerencia@rutaim.com"]

  def completion_email
    @attempt = params[:attempt]
    @student = @attempt.student

    mail(
      subject: "Quiz completado — #{@student.name} — #{@attempt.score}/#{@attempt.total_questions}"
    )
end
end
