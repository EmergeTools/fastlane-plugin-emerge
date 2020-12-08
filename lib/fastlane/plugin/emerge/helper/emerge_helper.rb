require 'fastlane_core/ui/ui'
require 'faraday'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class EmergeHelper
      def self.perform_upload(upload_url, upload_id, file_path)
        UI.message("Starting upload")
        response = Faraday.put(upload_url) do |req|
          req.headers['Content-Type'] = 'application/zip'
          req.headers['Content-Length'] = "#{File.size(file_path)}"
          req.body = Faraday::UploadIO.new(file_path, 'application/zip')
        end
        case response.status
        when 200
          UI.success("Your app is processing, you can find the results at https://emergetools.com/build/#{upload_id}")
        else
          UI.error("Upload failed")
        end
      end
    end
  end
end
