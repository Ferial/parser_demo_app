module XmlParser
  module Helpers

    private

    def is_element_start?(node)
      node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
    end

    def look_for_el(node_name, args={})
      node = args[:at]
      if node.name == node_name && is_element_start?(node)
        Nokogiri::XML(node.outer_xml, nil, "UTF-8").root
      end
    end

  end
end
