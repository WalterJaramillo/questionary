class QuizController < ApplicationController
  QUESTIONS_PER_PAGE = 5
  TOTAL_PAGES = 6

  def landing
  end

  def start
    cedula = params[:cedula].to_s.strip
    name = params[:name].to_s.strip
    email = params[:email].to_s.strip

    if cedula.blank? || name.blank? || email.blank?
      flash.now[:alert] = "Todos los campos son obligatorios"
      render :landing, status: :unprocessable_entity and return
    end

    student = Student.find_or_create_by(cedula: cedula) do |s|
      s.name = name
      s.email = email
    end

    unless student.can_take_quiz?
      flash.now[:alert] = "Ya has realizado el máximo de intentos permitidos"
      render :landing, status: :unprocessable_entity and return
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

    @page = [params[:page].to_i, 1].max
    @total_pages = TOTAL_PAGES

    start_idx = (@page - 1) * QUESTIONS_PER_PAGE
    page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE]
    @questions = Question.where(id: page_ids).to_a
    @questions.sort_by! { |q| session[:question_ids].index(q.id) }
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

    answers_params = params[:answers]
    answers_hash = answers_params&.to_unsafe_h || {}

    session[:answers] ||= {}
    session[:answers].merge!(answers_hash)

    total_answered = session[:answers].size
    next_page = params[:next_page].to_i

    if next_page > 0 && next_page <= TOTAL_PAGES
      start_idx = (@page.to_i - 1) * QUESTIONS_PER_PAGE
      page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE].map(&:to_s)
      unanswered = page_ids.reject { |id| session[:answers][id].present? }

      if unanswered.any?
        flash.now[:alert] = "Debes responder todas las preguntas de esta página antes de continuar"
        @page = @page.to_i
        @total_pages = TOTAL_PAGES
        page_ids_for_view = session[:question_ids][start_idx, QUESTIONS_PER_PAGE]
        @questions = Question.where(id: page_ids_for_view).to_a
        @questions.sort_by! { |q| session[:question_ids].index(q.id) }
        @attempt = attempt
        @answered = session[:answers]
        render :quiz, status: :unprocessable_entity and return
      end
    end

    if attempt.completed?
      redirect_to results_path(attempt), alert: "Este intento ya fue completado" and return
    end

    unless session[:question_ids].present?
      redirect_to root_path, alert: "Sesión expirada. Por favor inicia de nuevo." and return
    end

    answers_params = params[:answers]
    answers_hash = answers_params&.to_unsafe_h || {}

    session[:answers] ||= {}
    session[:answers].merge!(answers_hash)

    total_answered = session[:answers].size
    next_page = params[:next_page].to_i

    if next_page > 0 && next_page <= TOTAL_PAGES
      start_idx = (@page.to_i - 1) * QUESTIONS_PER_PAGE
      page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE].map(&:to_s)
      unanswered = page_ids.reject { |id| session[:answers][id].present? }

      if unanswered.any?
        flash.now[:alert] = "Debes responder todas las preguntas de esta página antes de continuar"
        @page = @page.to_i
        @total_pages = TOTAL_PAGES
        page_ids_for_view = session[:question_ids][start_idx, QUESTIONS_PER_PAGE]
        @questions = Question.where(id: page_ids_for_view).to_a
        @questions.sort_by! { |q| session[:question_ids].index(q.id) }
        @attempt = attempt
        @answered = session[:answers]
        render :quiz, status: :unprocessable_entity and return
      end
    end

    if attempt.completed?
      redirect_to results_path(attempt), alert: "Este intento ya fue completado" and return
    end

    unless session[:question_ids].present?
      redirect_to root_path, alert: "Sesión expirada. Por favor inicia de nuevo." and return
    end

    answers_params = params[:answers]
    answers_hash = answers_params&.to_unsafe_h || {}

    session[:answers] ||= {}
    session[:answers].merge!(answers_hash)

    total_answered = session[:answers].size
    next_page = params[:next_page].to_i

    if next_page > 0 && next_page <= TOTAL_PAGES
      start_idx = (@page.to_i - 1) * QUESTIONS_PER_PAGE
      page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE].map(&:to_s)
      unanswered = page_ids.reject { |id| session[:answers][id].present? }

      if unanswered.any?
        flash.now[:alert] = "Debes responder todas las preguntas de esta página antes de continuar"
        @page = @page.to_i
        @total_pages = TOTAL_PAGES
        page_ids_for_view = session[:question_ids][start_idx, QUESTIONS_PER_PAGE]
        @questions = Question.where(id: page_ids_for_view).to_a
        @questions.sort_by! { |q| session[:question_ids].index(q.id) }
        @attempt = attempt
        @answered = session[:answers]
        render :quiz, status: :unprocessable_entity and return
      end
    end

    if attempt.completed?
      redirect_to results_path(attempt), alert: "Este intento ya fue completado" and return
    end

    unless session[:question_ids].present?
      redirect_to root_path, alert: "Sesión expirada. Por favor inicia de nuevo." and return
    end

    answers_params = params[:answers]
    answers_hash = answers_params&.to_unsafe_h || {}

    session[:answers] ||= {}
    session[:answers].merge!(answers_hash)

    total_answered = session[:answers].size
    next_page = params[:next_page].to_i

    if next_page > 0 && next_page <= TOTAL_PAGES
      start_idx = (@page.to_i - 1) * QUESTIONS_PER_PAGE
      page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE].map(&:to_s)
      unanswered = page_ids.reject { |id| session[:answers][id].present? }

      if unanswered.any?
        flash.now[:alert] = "Debes responder todas las preguntas de esta página antes de continuar"
        @page = @page.to_i
        @total_pages = TOTAL_PAGES
        page_ids_for_view = session[:question_ids][start_idx, QUESTIONS_PER_PAGE]
        @questions = Question.where(id: page_ids_for_view).to_a
        @questions.sort_by! { |q| session[:question_ids].index(q.id) }
        @attempt = attempt
        @answered = session[:answers]
        render :quiz, status: :unprocessable_entity and return
      end
    end

    if attempt.completed?
      redirect_to results_path(attempt), alert: "Este intento ya fue completado" and return
    end

    unless session[:question_ids].present?
      redirect_to root_path, alert: "Sesión expirada. Por favor inicia de nuevo." and return
    end

    answers_params = params[:answers]
    answers_hash = answers_params&.to_unsafe_h || {}

    session[:answers] ||= {}
    session[:answers].merge!(answers_hash)

    total_answered = session[:answers].size
    next_page = params[:next_page].to_i

    if next_page > 0 && next_page <= TOTAL_PAGES
      start_idx = (@page.to_i - 1) * QUESTIONS_PER_PAGE
      page_ids = session[:question_ids][start_idx, QUESTIONS_PER_PAGE].map(&:to_s)
      unanswered = page_ids.reject { |id| session[:answers][id].present? }

      if unanswered.any?
        flash.now[:alert] = "Debes responder todas las preguntas de esta página antes de continuar"
        @page = @page.to_i
        @total_pages = TOTAL_PAGES
        page_ids_for_view = session[:question_ids][start_idx, QUESTIONS_PER_PAGE]
        @questions = Question.where(id: page_ids_for_view).to_a
        @questions.sort_by! { |q| session[:question_ids].index(q.id) }
        @attempt = attempt
        @answered = session[:answers]
        render :quiz, status: :unprocessable_entity and return
      end
    end

    if total_answered < 30
      redirect_to quiz_path(page: next_page) and return
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
