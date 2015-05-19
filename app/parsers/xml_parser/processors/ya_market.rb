module XmlParser
  module Processors

    class YaMarket < BaseProcessor

      private

      def build_item item_el
        {
          title:           item_el.first_element_child.text,
          partner_item_id: item_el[:id].to_i
        }
      end

      def build_items_data xml
        xml.each do |node|
          item_el = look_for_el("item", at: node)
          if item_el
            if item_el[:available] == "true"
              @available_items << build_item(item_el)
            else
              @not_available_items_partner_item_ids << item_el[:id]
            end
          end
        end
      end
      # может и можно вынести этот метод в BaseProcessor,
      # но для этого неплохо бы увидеть структруру xml файлов
      # большого числа конкретных магазинов

    end

  end
end
