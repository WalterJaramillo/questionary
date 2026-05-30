class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students do |t|
      t.string :cedula, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.integer :attempts_count, null: false, default: 0

      t.timestamps
    end
    add_index :students, :cedula, unique: true
  end
end
