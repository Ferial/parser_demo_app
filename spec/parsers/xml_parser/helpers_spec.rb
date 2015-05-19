require 'rails_helper'

describe XmlParser::Helpers do
  class DummyClass;end

  before :all do
    @dummy = DummyClass.new
    @dummy.extend XmlParser::Helpers
  end

  describe "#is_element_start?" do
    it "it check that node type is 'element'" do
      result = []
      reader = Nokogiri::XML::Reader("<item></item>")

      reader.each do |node|
        result << @dummy.send(:is_element_start?, node)
      end

      expect(result).to eq [true, false]
    end
  end

  describe "#look_for_el" do
    it "looks for element by name at provided node" do
      result = nil
      reader = Nokogiri::XML::Reader("<items><item></item></items>")

      reader.each do |node|
        element = @dummy.send(:look_for_el, "item", at: node)
        result = element if element
      end

      expect(result.to_xml).to eq "<item/>"
    end
  end

end
