class AddZonaToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :zona, :string, null: false, default: ""
  end
end
