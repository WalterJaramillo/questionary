require "test_helper"
require "roo"
require "tempfile"

class QuizImportTest < ActiveSupport::TestCase
  def create_test_excel(path, sheet_name: "FORMATO PARA APP", columns: nil, rows: 217)
    xlsx = Roo::Excelx.new(nil)
    # Create a simple CSV instead of Excel for testing
    csv_path = path.gsub(".xlsx", ".csv")

    headers = columns || %w[ITEM PREGUNTA A B C D RESPUESTA CORRECTA]
    File.open(csv_path, "w") do |f|
      f.puts headers.join(",")
      (1..rows).each do |i|
        f.puts "#{i},Question #{i},Option A,Option B,Option C,Option D,a"
      end
    end
    csv_path
  end

  test "import creates questions from Excel" do
    skip "Requires manual Excel file"
  end

  test "import is idempotent" do
    skip "Requires manual Excel file"
  end

  test "import fails with missing sheet" do
    skip "Requires manual Excel file"
  end

  test "import fails with missing columns" do
    skip "Requires manual Excel file"
  end
end
