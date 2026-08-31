require 'tempfile'

describe Fastlane::Helper::EmergeHelper do
  describe '.upload_file' do
    let(:api_token) { 'api-token' }
    let(:upload_url) { 'https://uploads.example.com/archive' }
    let(:request) { Struct.new(:headers, :body).new }

    it 'streams the binary file with the expected headers' do
      payload = "\x00\xFFbinary\x80data".b
      response = instance_double(Faraday::Response, status: 200)

      Tempfile.create(['archive', '.zip']) do |file|
        file.binmode
        file.write(payload)
        file.flush

        expect(Faraday).to receive(:put).with(upload_url) do |&block|
          block.call(request)

          expect(request.headers).to include(
            'Content-Type' => 'application/zip',
            'Content-Length' => payload.bytesize.to_s,
            'X-API-Token' => api_token
          )
          expect(request.body).to be_a(File)
          expect(request.body.read).to eq(payload)

          response
        end

        described_class.send(:upload_file, api_token, upload_url, file.path)

        expect(request.body).to be_closed
      end
    end

    it 'raises when the upload fails' do
      response = instance_double(Faraday::Response, status: 503)
      allow(Faraday).to receive(:put).and_yield(request).and_return(response)

      Tempfile.create(['archive', '.zip']) do |file|
        expect do
          described_class.send(:upload_file, api_token, upload_url, file.path)
        end.to raise_error('Uploading zip file failed 503')
      end

      expect(request.body).to be_closed
    end
  end
end
