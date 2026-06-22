class Admin::ResultsController < Admin::ApplicationController
  def index
    @q = Attempt.completed.joins(:student)
      .includes(:student)
      .ransack(params[:q])
    @attempts = @q.result
      .order(completed_at: :desc)
      .paginate(page: params[:page], per_page: 20)
  end

  def export
    attempts = Attempt.completed.joins(:student)
      .includes(:student)
      .ransack(params[:q]).result
      .order(completed_at: :desc)

    send_data ResultsExcelExporter.generate(attempts),
      filename: "resultados_#{Date.today}.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end
end
