class Student < ApplicationRecord
  MAX_ATTEMPTS = 1

  ZONAS = {
    "Zona Meta" => [
      "Piedemonte", "Provincia", "Nare", "Tibu",
      "Neiva", "Putumayo", "Rubiales"
    ],
    "Otras zonas" => [
      "CP9", "Castilla", "Chichimene", "Apiay"
    ]
  }.freeze

  has_many :attempts, dependent: :destroy

  validates :cedula, presence: true, uniqueness: true, format: { with: /\A\d+\z/, message: "solo puede contener números" }
  validates :name, presence: true
  validates :email, presence: true
  validates :zona, presence: true, inclusion: { in: ZONAS.values.flatten, message: "no es válida" }

  def can_take_quiz?
    attempts_count < MAX_ATTEMPTS
  end

  def latest_in_progress_attempt
    attempts.where(status: "in_progress").last
  end
end
