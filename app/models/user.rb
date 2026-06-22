class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum :role, { admin: "admin" }

  validates :role, inclusion: { in: %w[admin] }
end
