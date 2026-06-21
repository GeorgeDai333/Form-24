class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :card_1
      t.integer :card_2
      t.integer :card_3
      t.integer :card_4
      t.string :status

      t.timestamps
    end
  end
end
