#encoding: utf-8

require 'rails_helper'

describe XmlParser::Processors::YaMarket do

  before :all do
    @xml = Nokogiri::XML::Reader(<<-eoxml)
      <items>
        <item available="true" id="123">
          <title>Рубашка</title>
        </item>
        <item available="true" id="124">
          <title>Футболка</title>
        </item>
        <item available="false" id="125">
          <title>Толстовка</title>
        </item>
      </items>
    eoxml
    @processor = XmlParser::Processors::YaMarket.new(@xml)
  end

  describe "#build_item" do
    it "builds item hash from Nokogiri::XML::Element object" do
      result = nil
      xml = <<-eoxml
        <item available="true" id="123">
          <title>Рубашка</title>
        </item>
      eoxml
      item_el = Nokogiri::XML(xml, nil, "UTF-8").root

      result = @processor.send(:build_item, item_el)

      expect(result).to eq({ title: "Рубашка", partner_item_id: 123 })
    end
  end

  describe "#build_items_data" do
    it "fill arrays of available items and not available items ids" do
      result = []

      @processor.send(:build_items_data, @xml)
      result << @processor.instance_variable_get("@available_items").count
      result << @processor.instance_variable_get("@not_available_items_partner_item_ids").count

      expect(result).to eq [2, 1]
    end
  end

end
