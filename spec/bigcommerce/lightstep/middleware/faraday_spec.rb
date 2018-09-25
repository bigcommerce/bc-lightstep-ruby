RSpec.describe Bigcommerce::Lightstep::Middleware::Faraday do
  let(:test_host) { 'http://example.com' }
  let(:mock_response) do
    { data: [{ id: 0 }, { id: 1 }] }
  end

  subject { connection.get('/test/mock-data.json') }

  before do
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.com/test/mock-data.json')
      .to_return(status: 200, body: JSON.generate(mock_response), headers: {})
  end

  after do
    WebMock.allow_net_connect!
  end

  describe 'when we are not using the middleware' do
    let(:connection) { Faraday.new(url: test_host) }

    it 'will parse response' do
      expect(subject.body).to eq JSON.generate(mock_response)
    end
  end

  describe 'when we are using the middleware' do
    let(:connection) do
      Faraday.new(url: test_host) do |faraday|
        faraday.use Bigcommerce::Lightstep::Middleware::Faraday, 'name-of-external-service'
      end
    end

    it 'will parse response' do
      expect(subject.body).to eq JSON.generate(mock_response)
    end
  end
end
