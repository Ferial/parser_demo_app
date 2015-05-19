# encoding: utf-8

require 'fileutils'

namespace :demo do
  desc "Create db and demo data in it"
  task create_db: ["environment", "db:drop", "db:create", "db:migrate"] do
    create_demo_db
    puts "create demo db"
  end

  desc "Generates demo 'items.xml' in provided path"
  task :generate_demo_xml_file_to_dir, [:dir_path] => [:environment] do |t, args|
    generate_demo_xml_file_to_dir(args[:dir_path])
    puts "generate demo xml to file #{args[:dir_path]}"
  end
end

@titles = [
  'Сорочка ночная',
  'Сорочка',
  'Пижама',
  'Халат',
  'Платье-халат',
  'Комбинезон',
  'Платье',
  'Водолазка',
  'Блузка',
  'Футболка',
  'Туника',
  'Жилет',
  'Толстовка',
  'Брюки',
  'Сарафан',
  'Полукомбинезон',
  'Рубашка'
]

def create_partner
  Partner.create(
                  xml_url:  'http://0.0.0.0:8000/items.xml',
                  xml_type: 'YaMarket'
                )
end

def create_demo_db
  partner = create_partner

  item_columns = [
    :title,
    :partner_id,
    :partner_item_id,
    :available_in_store
  ]

  items = []

  1.upto(100000) do |i|
    items << [
      @titles.sample, # title
      partner.id,     # partner_id
      i,              # partner_item_id
      true            # available_in_store
    ]
  end

  Item.import(item_columns, items, validate: false)
end

def generate_demo_xml_file_to_dir(dir_path)
  builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml.items {
      # not available items
      1.upto(50000) { |i|
        xml.item(available: "false", id: i) {
          xml.title "item_title"
        }
      }

      # items to update (if partner exist, if not -> new items)
      50001.upto(80000) { |i|
        xml.item(available: "true", id: i) {
          xml.title "item_to_update_title"
        }
      }

      # new items
      80001.upto(100000) { |i|
        xml.item(available: "true", id: i + 100000) {
          xml.title "new_item_title"
        }
      }
    }
  end

  FileUtils::mkdir_p(dir_path) unless File.exists?(dir_path)

  open("#{dir_path}/items.xml", "w:UTF-8") do |f|
    f.puts builder.doc.root
  end
end
