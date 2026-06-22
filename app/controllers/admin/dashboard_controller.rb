class Admin::DashboardController < Admin::ApplicationController
  def index
    @total_students = Student.count
    @total_attempts = Attempt.completed.count
    @avg_score = Attempt.completed.average(:score)&.to_f || 0
    @avg_percentage = @total_attempts > 0 ? ((@avg_score / 30) * 100).round : 0
    @recent_7_days = Attempt.completed.where("completed_at >= ?", 7.days.ago).count

    @by_zone = Attempt.completed.joins(:student)
      .group("students.zona")
      .order(Arel.sql("AVG(attempts.score) DESC"))
      .average("attempts.score")

    @score_distribution = Attempt.completed
      .group(Arel.sql("FLOOR(score / 5) * 5"))
      .order(Arel.sql("FLOOR(score / 5) * 5"))
      .count
  end
end
