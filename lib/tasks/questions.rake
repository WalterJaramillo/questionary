require "roo"

namespace :questions do
  desc "Import questions from Excel file"
  task import: :environment do
    excel_path = ENV.fetch("EXCEL_PATH", Rails.root.join("Evaluacion Tecnica preguntas 28-5-2026.xlsx").to_s)

    unless File.exist?(excel_path)
      puts "ERROR: File not found: #{excel_path}"
      puts "Usage: EXCEL_PATH=/path/to/file.xlsx rake questions:import"
      exit 1
    end

    puts "Opening Excel file: #{excel_path}"
    workbook = Roo::Spreadsheet.open(excel_path)

    sheet_name = "FORMATO PARA APP"
    unless workbook.sheets.include?(sheet_name)
      puts "ERROR: Sheet '#{sheet_name}' not found. Available sheets: #{workbook.sheets.join(', ')}"
      exit 1
    end

    workbook.default_sheet = sheet_name

    required_columns = [ "ITEM", "SECCIÓN", "TEMA", "PREGUNTA", "A", "B", "C", "D", "RESPUESTA CORRECTA" ]
    header_row = workbook.row(1).map { |cell| cell.to_s.strip.upcase }
    missing_columns = required_columns.reject { |col| header_row.include?(col) }

    if missing_columns.any?
      puts "ERROR: Missing required columns: #{missing_columns.join(', ')}"
      puts "Found columns: #{header_row.join(', ')}"
      exit 1
    end

    col_map = {}
    required_columns.each do |col|
      col_map[col] = header_row.index(col)
    end

    created = 0
    skipped = 0

    (2..workbook.last_row).each do |row_num|
      item = workbook.cell(row_num, col_map["ITEM"] + 1)
      next if item.nil?

      if Question.exists?(item: item.to_i)
        skipped += 1
        next
      end

      seccion = workbook.cell(row_num, col_map["SECCIÓN"] + 1).to_s.strip
      tema = workbook.cell(row_num, col_map["TEMA"] + 1).to_s.strip
      question_text = workbook.cell(row_num, col_map["PREGUNTA"] + 1)
      option_a = workbook.cell(row_num, col_map["A"] + 1)
      option_b = workbook.cell(row_num, col_map["B"] + 1)
      option_c = workbook.cell(row_num, col_map["C"] + 1)
      option_d = workbook.cell(row_num, col_map["D"] + 1)
      correct_raw = workbook.cell(row_num, col_map["RESPUESTA CORRECTA"] + 1).to_s.strip.downcase

      correct_letter = correct_raw[/^[a-d]/]
      unless correct_letter
        puts "WARNING: Row #{row_num} - Invalid correct answer: '#{correct_raw}', skipping"
        skipped += 1
        next
      end

      Question.create!(
        item: item.to_i,
        seccion: seccion,
        tema: tema,
        question_text: question_text.to_s,
        option_a: option_a.to_s,
        option_b: option_b.to_s,
        option_c: option_c.to_s,
        option_d: option_d.to_s,
        correct_answer: correct_letter
      )

      created += 1
    end

    puts "Import complete: #{created} created, #{skipped} skipped"
  end
end
