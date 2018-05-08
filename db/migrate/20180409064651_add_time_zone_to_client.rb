class AddTimeZoneToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :timezone, :string
  end
end
