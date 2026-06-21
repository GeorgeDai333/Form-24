class CreateForm24Games < ActiveRecord::Migration[7.0]
  def change
    create_table :form24_games do |t|
      t.text :deck
      t.text :hand
      t.integer :draws, default: 0, null: false
      t.integer :penalty, default: 0, null: false
      t.references :user, foreign_key: true, null: true

      t.timestamps
    end
  end
end
