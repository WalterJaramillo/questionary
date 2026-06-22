class QuizController < ApplicationController
  QUESTIONS_PER_PAGE = 5
  TOTAL_PAGES = 6

  def landing
  end

  def start
    cedula = params[:cedula].to_s.strip
    name = params[:name].to_s.strip
    email = params[:email].to_s.strip
    zona = params[:zona].to_s.strip

    if cedula.blank? || name.blank? || email.blank? || zona.blank?
      flash[:alert] = "Todos los campos son obligatorios"
      redirect_to root_path and return
    end

    if params[:policy_accepted] != "1"
      flash[:alert] = "Debes aceptar la política de tratamiento de datos"
      redirect_to root_path and return
    end

    student = Student.find_or_create_by(cedula: cedula) do |s|
      s.name = name
      s.email = email
      s.zona = zona
    end

    unless student.can_take_quiz?
      flash[:alert] = "Ya has realizado el máximo de intentos permitidos"
      redirect_to root_path and return
    end

    attempt = student.attempts.create!(
      status: "in_progress",
      started_at: Time.current
    )

    session[:attempt_id] = attempt.id
    session[:question_ids] = Question.random_sample.pluck(:id)
    session[:answers] = {}

    redirect_to quiz_path
  end

  def quiz
    attempt = current_attempt
    unless attempt
      redirect_to root_path, alert: "No hay un intento activo" and return
    end

    if attempt.expired?
      redirect_to submit_quiz_path(auto_submit: true) and return
    end

    @time_remaining = attempt.time_remaining
    @time_remaining_formatted = attempt.time_remaining_formatted
    @show_all_questions = @time_remaining < 300

    if @show_all_questions
      @page = 1
      @total_pages = 1
      @questions_per_page = 30
      @questions = Question.where(id: session[:question_ids]).to_a
      @questions.sort_by! { |q| session[:question_ids].index(q.id) }
    else
      @page = [ params[:page].to_i, 1 ].max
      @total_pages = TOTAL_PAGES
      @questions_per_page = QUESTIONS_PER_PAGE

      start_idx = (@page - 1) * QUESTIONS_PER_PAGE
      page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE]
      @questions = Question.where(id: page_ids).to_a
      @questions.sort_by! { |q| session[:question_ids].index(q.id) }
    end

    @attempt = attempt
    @answered = session[:answers] || {}
  end

  def submit
    attempt = current_attempt || completed_attempt
    unless attempt
      redirect_to root_path, alert: "No hay un intento activo" and return
    end

    if attempt.completed?
      redirect_to results_path(attempt), alert: "Este intento ya fue completado" and return
    end

    unless session[:question_ids].present?
      redirect_to root_path, alert: "Sesión expirada. Por favor inicia de nuevo." and return
    end

    answers_hash = params[:answers]&.to_unsafe_h || {}
    session[:answers] ||= {}
    session[:answers].merge!(answers_hash)

    auto_submit = params[:auto_submit] == "true"
    is_expired = attempt.expired?

    if !auto_submit && !is_expired
      next_page = params[:next_page].to_i

      if next_page > 0 && next_page <= TOTAL_PAGES
        current_page = [ params[:page].to_i, 1 ].max
        start_idx = (current_page - 1) * QUESTIONS_PER_PAGE
        page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE].map(&:to_s)
        unanswered = page_ids.reject { |id| session[:answers][id].present? }

        if unanswered.any?
          flash[:alert] = "Debes responder todas las preguntas de esta página antes de continuar"
          redirect_to quiz_path(page: current_page) and return
        end

        redirect_to quiz_path(page: next_page) and return
      end

      if session[:answers].size < 30
        flash[:alert] = "Debes responder todas las preguntas antes de enviar"
        redirect_to quiz_path and return
      end
    end

    begin
      attempt.complete!(session[:answers])
    rescue => e
      Rails.logger.error "Error completing attempt: #{e.message}"
      flash[:alert] = "Error al procesar las respuestas. Intenta de nuevo."
      redirect_to quiz_path and return
    end

    begin
      ResultMailer.with(attempt: attempt).completion_email.deliver_now
    rescue => e
      Rails.logger.error "Error sending email: #{e.message}"
    end

    session.delete(:question_ids)
    session.delete(:answers)

    redirect_to results_path(attempt)
  end

  def results
    @attempt = Attempt.find_by(id: params[:id])

    unless @attempt && @attempt.completed?
      redirect_to root_path, alert: "Resultado no encontrado" and return
    end

    if session[:attempt_id].to_s != @attempt.id.to_s
      redirect_to root_path, alert: "No tienes acceso a este resultado" and return
    end

    @student = @attempt.student
    @weak_topics = @attempt.weak_topics
  end

  private

  def current_attempt
    return unless session[:attempt_id]

    Attempt.find_by(id: session[:attempt_id], status: "in_progress")
  end

  def completed_attempt
    return unless session[:attempt_id]

    Attempt.find_by(id: session[:attempt_id], status: "completed")
  end
end
