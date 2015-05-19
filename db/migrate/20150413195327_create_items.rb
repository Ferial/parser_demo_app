class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :title
      t.integer :partner_id
      t.integer :partner_item_id
      t.boolean :available_in_store

      t.timestamps null: false
    end

    add_index :items,
               ["partner_id", "partner_item_id"],
               unique: true,
               name: "partner_id_partner_item_id_ix"
  end
end
