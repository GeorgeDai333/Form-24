class Form24GamesController < ApplicationController
  CARD_RANKS = %w[A 2 3 4 5 6 7 8 9 10 J Q K].freeze
  SUITS = %w[C D H S].freeze

  def new
  end

  def create
    deck = build_deck.shuffle
    user = respond_to?(:current_user) ? current_user : nil
    game = Form24Game.create!(deck: deck.to_json, hand: [].to_json, draws: 0, penalty: 0, user: user)
    game.initial_draw!(4)
    redirect_to form24_game_path(game)
  end

  def show
    @game = Form24Game.find_by(id: params[:id])
    unless @game
      redirect_to new_form24_game_path, alert: 'Game not found'
      return
    end
    @cards = @game.hand_array
  end

  def validate
    @game = Form24Game.find_by(id: params[:id])
    unless @game
      render json: { ok: false, error: 'Game not found' }, status: :not_found
      return
    end

    cards = @game.hand_array
    expression = params[:expression].to_s
    unless cards.present?
      render json: { ok: false, error: 'No active hand' }, status: :unprocessable_entity
      return
    end

    result = Form24Evaluator.validate_solution(cards.map { |c| card_value(c) }, expression)
    if result[:ok]
      # increment score and deal the next hand
      @game.win_and_deal_next!(4)
      render json: { ok: true, message: 'Correct! You made 24.', hand: @game.hand_array, cards_left: @game.cards_left,
                     draws: @game.draws, penalty: @game.penalty, score: @game.score }
    else
      render json: { ok: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  def new_hand
    @game = Form24Game.find_by(id: params[:id])
    unless @game
      redirect_to new_form24_game_path, alert: 'Game not found'
      return
    end
    @game.new_hand!(4)
    redirect_to form24_game_path(@game), notice: 'New hand dealt.'
  end

  def draw
    @game = Form24Game.find_by(id: params[:id])
    unless @game
      redirect_to new_form24_game_path, alert: 'Game not found'
      return
    end

    begin
      @game.draw_card!
      redirect_to form24_game_path(@game), notice: 'Drew one card (penalty applied)'
    rescue StandardError => e
      redirect_to form24_game_path(@game), alert: e.message
    end
  end

  private

  def build_deck
    deck = []
    CARD_RANKS.each do |rank|
      SUITS.each do |suit|
        deck << "#{rank}#{suit}"
      end
    end
    deck
  end

  def card_value(code)
    rank = code[0..-2]
    case rank
    when 'A' then 1
    when 'J' then 11
    when 'Q' then 12
    when 'K' then 13
    else
      rank.to_i
    end
  end
end
