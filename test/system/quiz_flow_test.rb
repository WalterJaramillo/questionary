require "application_system_test_case"

class QuizFlowTest < ApplicationSystemTestCase
  test "complete quiz flow end-to-end" do
    visit root_path

    fill_in "cedula", with: "999888777"
    fill_in "name", with: "System Test User"
    fill_in "email", with: "system@test.com"
    select "Piedemonte", from: "zona"
    click_button "Iniciar Evaluación"

    assert_current_path quiz_path

    questions = Question.random_sample.to_a
    questions.first(5).each do |question|
      choose("q#{question.id}_a")
    end

    click_button "Siguiente"

    questions[5..9].each do |question|
      choose("q#{question.id}_a")
    end

    click_button "Siguiente"

    questions[10..14].each do |question|
      choose("q#{question.id}_a")
    end

    click_button "Siguiente"

    questions[15..19].each do |question|
      choose("q#{question.id}_a")
    end

    click_button "Siguiente"

    questions[20..24].each do |question|
      choose("q#{question.id}_a")
    end

    click_button "Siguiente"

    questions[25..29].each do |question|
      choose("q#{question.id}_a")
    end

    click_button "Enviar Respuestas"

    assert_text "Resultados"
    assert_text "de 30"
  end
end
