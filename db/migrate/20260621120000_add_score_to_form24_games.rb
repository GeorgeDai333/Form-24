class AddScoreToForm24Games < ActiveRecord::Migration[7.0]
  def change
    add_column :form24_games, :score, :integer, default: 0, null: false
  end
end
