# encoding: utf-8

module XmlParser

  class Parser
    require 'open-uri'
    require 'fileutils'

    NET_ERRORS = [
      EOFError,
      Errno::ENOENT,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Errno::ECONNREFUSED,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error,
      OpenURI::HTTPError
    ]

    attr_reader :partner,
                :available_items,
                :not_available_items_partner_item_ids,
                :batch_size

    def self.init(partner_info = {})
      partner = Partner.new partner_info
      if partner.valid?
        new partner_info
      else
        print_validation_errors_for partner
        nil
      end
    end

    def initialize(partner_info = {})
      @batch_size                           = nil # default value
      @partner                              = get_partner_record(partner_info)
      @available_items                      = []
      @not_available_items_partner_item_ids = []
    end

    # parser = XmlParser::Parser.init(xml_url: 'http://0.0.0.0:8000/items.xml', xml_type: "YaMarket")

    def parse(args = { save: true })
      start_time = Time.now

      @batch_size = args[:batch_size] if args[:batch_size]
      sync_parsed = args[:save]

      temp_file_path = download_file @partner.xml_url
      return unless temp_file_path

      xml = Nokogiri::XML::Reader open(temp_file_path)

      data_from_xml = process_xml(xml)

      if data_from_xml
        @available_items, @not_available_items_partner_item_ids = data_from_xml
      else
        return
      end

      save if sync_parsed

      File.delete temp_file_path

      puts "process took: #{Time.now - start_time} seconds!"
    end

    def save(args = {})
      @batch_size = args[:batch_size] if args[:batch_size]
      db_writer = DatabaseWriter.new(self)
      db_writer.save
    end

    private

    def self.print_validation_errors_for(active_record_obj)
      klass_name = active_record_obj.class.name
      puts "Ivalid #{klass_name}!"
      active_record_obj.errors.messages.each do |attr, errors|
        puts "#{attr}:"
        errors.each { |error| puts "-> #{error}" }
      end
    end

    def get_partner_record(partner_info = {})
      partner_record = Partner.where(
                         xml_url:  partner_info[:xml_url],
                         xml_type: partner_info[:xml_type]
                       ).first

      partner_record = Partner.new(
                         xml_url:  partner_info[:xml_url],
                         xml_type: partner_info[:xml_type]
                       ) unless partner_record
      partner_record
    end

    def create_temp_dir
      dir_path = Rails.root.join("tmp/xml_parser").to_s
      unless File.exists? dir_path
        FileUtils::mkdir_p dir_path
      end
    end

    def download_file(url)
      create_temp_dir

      created_at = DateTime.now.strftime "%Y.%m.%d[%H:%M:%S]"

      output_file_path = Rails.root.join("tmp/items_#{created_at}.xml").to_s

      start_time = Time.now

      begin
        open(output_file_path, 'w:UTF-8') { |f| f << open(url, 'r:UTF-8').read }
      rescue *NET_ERRORS => e
        File.delete output_file_path
        msg = "Something went wrong while downloading file from URL: #{url}"
        Rails.logger.info("#{msg} -> #{e}")
        return
      end

      puts "file download took: #{Time.now - start_time} seconds!"

      output_file_path
    end

    def process_xml(xml)
      {
        "YaMarket" => ->{ Processors::YaMarket.new(xml).process }#,
        # "SomeMarket"  => ->{ Processors::SomeMarket.new(xml).process },
        # "OtherMarket" => ->{ Processors::OtherMarket.new(xml).process },
        # "AnyMarket"   => ->{ Processors::AnyMarket.new(xml).process }
        # и т.д.
      }[@partner.xml_type].call
    end

  end

end
