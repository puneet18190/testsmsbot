class CreateClients < ActiveRecord::Migration[5.1]
  def change
    create_table :clients do |t|
      t.string :clientid
      t.string :mobile
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :avg_revenue
      t.integer :sms_status, default: 0
      # t.text :results

      t.timestamps
    end
  end
end
