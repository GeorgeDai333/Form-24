class User < ApplicationRecord
  has_many :participations
  has_many :matches, through: :participations

  def total_score
    participations.sum(:score)
  end
end
