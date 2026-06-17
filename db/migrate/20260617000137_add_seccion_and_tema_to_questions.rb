class AddSeccionAndTemaToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :seccion, :string
    add_column :questions, :tema, :string
  end
end
