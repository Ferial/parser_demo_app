class Partner < ActiveRecord::Base
  has_many :items, dependent: :delete_all

  validates :xml_type, :xml_url, presence: true

  validate :xml_processor_existence#, :url_format

  private

  # Нужно знать формат url
  # def url_format
  # end

  def xml_processor_existence
    processor_class = nil

    processor_class = suppress NameError do
      "XmlParser::Processors::#{self.xml_type}".constantize
    end

    unless processor_class
      errors.add(:xml_type, "processor not found")
    end
  end

end
