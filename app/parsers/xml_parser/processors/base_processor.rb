module XmlParser
  module Processors

    class BaseProcessor
      include XmlParser::Helpers

      def initialize(xml)
        @xml = xml
        @available_items                      = []
        @not_available_items_partner_item_ids = []
      end

      def process
        begin
          build_items_data @xml
          # нужно определять в классе процессора конкретного магазина (см. YaMarket)
        rescue Nokogiri::XML::SyntaxError => e
          msg = "Something went wrong while processing XML file"
          Rails.logger.info ("#{msg} -> #{e}")
          return
        end
        [@available_items, @not_available_items_partner_item_ids]
      end

    end

  end
end
