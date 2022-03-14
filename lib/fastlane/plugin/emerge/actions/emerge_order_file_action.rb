require 'fastlane/action'
require 'tmpdir'
require 'tempfile'
require 'fileutils'

module Fastlane
  module Actions
    class EmergeOrderFileAction < Action
      def self.run(params)
        resp = Faraday.get("https://order-files-prod.emergetools.com/#{params[:app_id]}", nil, {'X-API-Token' => params[:api_token]})
        case resp.status
        when 200
          Tempfile.create do |f|
            f.write(resp.body)
            decompressed = IO.popen(['gunzip', '-c', f.path]).read
            IO.write(params[:output_path], decompressed)
          end
        when 401
          UI.error("Unauthorized")
        else
          UI.error("Failed to download order file code: #{resp.status}")
        end

      end
      def self.description
        "Fastlane plugin to download order files"
      end

      def self.authors
        ["Emerge Tools"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                  env_name: "EMERGE_API_TOKEN",
                               description: "An API token for Emerge",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :app_id,
                               description: "Id of the app being built with the order file",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                   description: "Path to the order file",
                                      optional: false,
                                          type: String)
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
