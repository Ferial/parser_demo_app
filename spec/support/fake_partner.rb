class FakePartner < Sinatra::Base
  get '/items.xml' do
    xml_response 200, 'items.xml'
  end

  private

  def xml_response(response_code, file_name)
    content_type :xml
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'r').read
  end
end
