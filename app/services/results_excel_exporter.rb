class ResultsExcelExporter
  def self.generate(attempts)
    package = Axlsx::Package.new
    wb = package.workbook

    wb.add_worksheet(name: "Resultados") do |sheet|
      sheet.add_row [
        "Cédula", "Nombre", "Email", "Zona",
        "Score", "Porcentaje", "Temas a reforzar", "Fecha"
      ]

      attempts.each do |attempt|
        student = attempt.student
        percentage = attempt.total_questions > 0 ? ((attempt.score.to_f / attempt.total_questions) * 100).round : 0
        weak_topics = attempt.weak_topics.map(&:first).join(", ")

        sheet.add_row [
          student.cedula,
          student.name,
          student.email,
          student.zona,
          "#{attempt.score}/#{attempt.total_questions}",
          "#{percentage}%",
          weak_topics,
          attempt.completed_at&.strftime("%Y-%m-%d %H:%M") || ""
        ]
      end

      sheet.column_widths 15, 25, 30, 15, 12, 12, 40, 20
    end

    package.to_stream.read
  end
end
