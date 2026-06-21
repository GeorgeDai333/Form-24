class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username
      t.integer :total_score

      t.timestamps
    end
  end
end
