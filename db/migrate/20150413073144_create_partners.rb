class CreatePartners < ActiveRecord::Migration
  def change
    create_table :partners do |t|
      t.string :xml_url
      t.string :xml_type

      t.timestamps null: false
    end
  end
end
