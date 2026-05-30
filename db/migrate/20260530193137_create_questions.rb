class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.integer :item, null: false
      t.text :question_text, null: false
      t.text :option_a, null: false
      t.text :option_b, null: false
      t.text :option_c, null: false
      t.text :option_d, null: false
      t.string :correct_answer, null: false

      t.timestamps
    end
    add_index :questions, :item, unique: true
  end
end
