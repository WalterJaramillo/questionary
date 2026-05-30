class CreateAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :attempts do |t|
      t.references :student, null: false, foreign_key: true
      t.integer :score, null: false, default: 0
      t.integer :total_questions, null: false, default: 30
      t.string :status, null: false, default: "in_progress"
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
