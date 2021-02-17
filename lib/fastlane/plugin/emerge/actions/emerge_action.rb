require 'fastlane/action'
require_relative '../helper/emerge_helper'

module Fastlane
  module Actions
    class EmergeAction < Action
      def self.run(params)
        api_token = params[:api_token]
        file_path = params[:file_path]
        pr_number = params[:pr_number]
        build_id = params[:build_id]
        base_build_id = params[:base_build_id]
        repo_name = params[:repo_name]
        build_type = params[:build_type]
        if !File.exist?(file_path) || !File.extname(file_path) == '.zip'
          UI.error("Invalid input file")
          return
        end

        fileName = File.basename(file_path)
        url = 'https://api.emergetools.com/getUpload'
        params = {
          fileName: fileName,
        }
        if pr_number
          params[:prNumber] = pr_number
        end
        if build_id
          params[:buildId] = build_id
        end
        if base_build_id
          params[:baseBuildId] = base_build_id
        end
        if repo_name
          params[:repoName] = repo_name
        end
        params[:buildType] = build_type || "development"
        resp = Faraday.get(url, params, {'X-API-Token' => api_token})
        case resp.status
        when 200
          json = JSON.parse(resp.body)
          upload_id = json["upload_id"]
          upload_url = json["uploadURL"]
          Helper::EmergeHelper.perform_upload(upload_url, upload_id, file_path)
        when 400...500
          UI.error("Invalid API token")
        else
          UI.error("Upload failed")
        end
      end

      def self.description
        "Fastlane plugin for Emerge"
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
          FastlaneCore::ConfigItem.new(key: :file_path,
                                  env_name: "EMERGE_FILE_PATH",
                               description: "Path to the zipped xcarchive or app to upload",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :pr_number,
                               description: "The PR number that triggered this upload",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :build_id,
                               description: "A string to identify this build",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :base_build_id,
                               description: "Id of the build to compare with this upload",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :repo_name,
                               description: "Full name of the respository this upload was triggered from. For example: EmergeTools/Emerge",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :build_type,
                               description: "Type of build, either release or development. Defaults to development",
                                  optional: true,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        platform == :ios
      end
    end
  end
end
