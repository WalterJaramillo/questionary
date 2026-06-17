class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :attempt, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :selected_option, null: false
      t.boolean :is_correct, null: false, default: false

      t.timestamps
    end
    add_index :answers, [ :attempt_id, :question_id ], unique: true
  end
end
