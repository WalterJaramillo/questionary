class Admin::ImportController < Admin::ApplicationController
  def index
    @total_questions = Question.count
  end

  def create
    unless params[:file].present?
      flash[:alert] = "Selecciona un archivo Excel"
      redirect_to admin_import_path and return
    end

    begin
      xlsx = Roo::Spreadsheet.open(params[:file].tempfile)
      imported = 0

      xlsx.each_row_streaming(offset: 1) do |row|
        question_text = row[1]&.value&.to_s&.strip
        option_a = row[2]&.value&.to_s&.strip
        option_b = row[3]&.value&.to_s&.strip
        option_c = row[4]&.value&.to_s&.strip
        option_d = row[5]&.value&.to_s&.strip
        correct_answer = row[6]&.value&.to_s&.strip&.downcase
        item = row[0]&.value&.to_i

        next if question_text.blank? || item.nil?

        Question.find_or_create_by!(item: item) do |q|
          q.question_text = question_text
          q.option_a = option_a
          q.option_b = option_b
          q.option_c = option_c
          q.option_d = option_d
          q.correct_answer = correct_answer
        end
        imported += 1
      end

      flash[:notice] = "#{imported} preguntas importadas correctamente"
      redirect_to admin_import_path
    rescue => e
      flash[:alert] = "Error al importar: #{e.message}"
      redirect_to admin_import_path
    end
  end
end
