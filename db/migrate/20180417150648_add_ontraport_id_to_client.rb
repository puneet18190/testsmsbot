class AddOntraportIdToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :ontraport_id, :string
  end
end
