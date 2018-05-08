class CreateResults < ActiveRecord::Migration[5.1]
  def change
    create_table :results do |t|
      t.string :resultid
      t.text :help
      t.string :revenue_last_month
      t.string :mobile_number
      # t.string :client
      t.string :income_goal
      t.string :date
      t.integer :client_id

      t.timestamps
    end
  end
end
