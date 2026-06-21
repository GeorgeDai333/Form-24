class Game < ApplicationRecord
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
end
