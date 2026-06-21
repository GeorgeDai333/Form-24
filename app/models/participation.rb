class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :match

  before_create :set_default_score

  private

  def set_default_score
    self.score ||= 0
  end
end
