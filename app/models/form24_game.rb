class Form24Game < ApplicationRecord
  belongs_to :user, optional: true

  CARD_RANKS = %w[A 2 3 4 5 6 7 8 9 10 J Q K].freeze
  SUITS = %w[C D H S].freeze

  def deck_array
    (deck.present? ? JSON.parse(deck) : [])
  end

  def hand_array
    (hand.present? ? JSON.parse(hand) : [])
  end

  def draw_card!
    d = deck_array
    raise 'No cards left' if d.empty?

    card = d.shift
    h = hand_array
    h << card
    self.deck = d.to_json
    self.hand = h.to_json
    self.draws = (draws || 0) + 1
    # simple penalty: increment by 1 per extra draw
    self.penalty = (penalty || 0) + 1
    save!
    card
  end

  def cards_left
    deck_array.size
  end

  def initial_draw!(count = 4)
    d = deck_array
    h = []
    count.times do
      h << d.shift
    end
    self.hand = h.to_json
    self.deck = d.to_json
    save!
  end

  def new_hand!(count = 4)
    # Draw the next `count` cards from the existing deck; do NOT reshuffle
    d = deck_array
    h = []
    if d.size >= count
      count.times { h << d.shift }
      self.hand = h.to_json
      self.deck = d.to_json
      # reset draws/penalty for the new hand
      self.draws = 0
      self.penalty = 0
      save!
    else
      # not enough cards left — reshuffle full deck and deal
      full = []
      CARD_RANKS.each do |rank|
        SUITS.each do |suit|
          full << "#{rank}#{suit}"
        end
      end
      full.shuffle!
      self.deck = full.to_json
      self.hand = [].to_json
      self.draws = 0
      self.penalty = 0
      save!
      initial_draw!(count)
    end
  end

  def win_and_deal_next!(count = 4)
    self.score = (score || 0) + 1
    # reset draws/penalty for the next hand
    self.draws = 0
    self.penalty = 0
    save!
    # if there aren't enough cards left, reshuffle into a new deck
    if cards_left < count
      new_hand!(count)
    else
      initial_draw!(count)
    end
  end
end
