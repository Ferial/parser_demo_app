require 'rails_helper'

def existing_partner_info
  {
    xml_url: "http://existing-partner.foo/items.xml",
    xml_type: "YaMarket"
  }
end

def new_partner_info
  {
    xml_url: "http://new-partner.foo/items.xml",
    xml_type: "YaMarket"
  }
end

def prepare_db
  partner = Partner.create(existing_partner_info)

  @item_to_update = Item.create(
    partner_id: partner.id,
    partner_item_id: 123,
    title: "Свитер",
    available_in_store: true
  )

  @item_to_mark_as_not_available = Item.create(
    partner_id: partner.id,
    partner_item_id: 124,
    title: "Платье",
    available_in_store: true
  )
end

describe XmlParser::Parser do

  before :each do
    prepare_db
    @items_count_before_parse = Item.count
    @partner_count_before_parse = Partner.count
    stub_request(:get, /partner.foo/).to_rack(FakePartner)
  end

  describe "#parse" do

    context "with 'save: false' parameter" do
      it "parse data without db sync" do
        @parser = XmlParser::Parser.init(new_partner_info)

        @parser.parse(save: false)

        expect(@parser.available_items).to eq [
          { title: "Джемпер",  partner_item_id: 123 },
          { title: "Футболка", partner_item_id: 125 }
        ]
        expect(@parser.not_available_items_partner_item_ids).to eq ["124"]
        expect(Item.count).to eq @items_count_before_parse
        expect(Partner.count).to eq @partner_count_before_parse
      end
    end

    context "existing partner" do
      it "parse data, update existing items, add new items, mark not available items" do
        @parser = XmlParser::Parser.init(existing_partner_info)

        @parser.parse

        expect(@item_to_update.reload.title).to eq "Джемпер"
        expect(@item_to_mark_as_not_available.reload.available_in_store).to eq false
        expect(Item.count).to be > @items_count_before_parse
        expect(Item.count).to eq 3
        expect(Partner.count).to eq @partner_count_before_parse
      end
    end

    context "new partner" do
      it "parse data, save new partner with all available items to db" do
        @parser = XmlParser::Parser.init(new_partner_info)

        @parser.parse

        expect(Item.count).to be > @items_count_before_parse
        expect(Item.count).to eq 4
        expect(Partner.count).to be > @partner_count_before_parse
        expect(Partner.count).to eq 2
      end
    end

  end

end
