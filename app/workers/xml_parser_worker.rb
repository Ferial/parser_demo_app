class XmlParserWorker
  include Sidekiq::Worker

  def perform(partner_info = {})
    parser = XmlParser::Parser.init(partner_info)
    parser.parse
  end

end
