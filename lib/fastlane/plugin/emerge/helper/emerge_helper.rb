require 'fastlane_core/ui/ui'
require 'faraday'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  class GitResult
    attr_accessor :sha, :base_sha, :branch, :pr_number, :repo_name

    def initialize(sha:, base_sha:, branch:, pr_number: nil, repo_name: nil)
      @pr_number = pr_number
      @sha = sha
      @base_sha = base_sha
      @branch = branch
      @repo_name = repo_name
    end
  end

  module Helper
    class EmergeHelper
      API_URL = 'https://api.emergetools.com/upload'.freeze

      def self.perform_upload(api_token, params, file_path)
        cleaned_params = clean_params(params)
        print_summary(cleaned_params)

        upload_response = create_upload(api_token, cleaned_params)
        handle_upload_response(api_token, upload_response, file_path)
      rescue StandardError => e
        UI.user_error!(e.message)
      end

      def self.make_git_params
        git_result = if Helper::Github.is_supported_github_event?
                       UI.message("Fetching Git info from Github event")
                       GitResult.new(
                         sha: Helper::Github.sha,
                         base_sha: Helper::Github.base_sha,
                         branch: Helper::Github.branch,
                         pr_number: Helper::Github.pr_number,
                         repo_name: Helper::Github.repo_name
                       )
                     else
                       UI.message("Fetching Git info from system Git")
                       GitResult.new(
                         sha: Helper::Git.sha,
                         base_sha: Helper::Git.base_sha,
                         branch: Helper::Git.branch
                       )
                     end
        UI.message("Got git result #{git_result.inspect}")
        git_result
      end

      def self.copy_config(config_path, tmp_dir)
        return if config_path.nil?

        expanded_path = File.expand_path(config_path)
        unless File.exist?(expanded_path)
          UI.error("No config file found at path '#{expanded_path}'.\nUploading without config file")
          return
        end

        emerge_config_path = "#{tmp_dir}/emerge_config.yaml"
        FileUtils.cp(expanded_path, emerge_config_path)
      end

      private_class_method

      def self.clean_params(params)
        params.reject { |_, v| v.nil? }
      end

      def self.print_summary(params)
        FastlaneCore::PrintTable.print_values(
          config: params,
          hide_keys: [],
          title: "Summary for Emerge Upload #{Fastlane::Emerge::VERSION}"
        )
      end

      def self.create_upload(api_token, params)
        response = Faraday.post(API_URL, params.to_json, headers(api_token, params, 'application/json'))
        parse_response(response)
      end

      def self.headers(api_token, params, content_type)
        {
          'Content-Type' => content_type,
          'X-API-Token' => api_token,
          'User-Agent' => "fastlane-plugin-emerge/#{Fastlane::Emerge::VERSION}"
        }
      end

      def self.parse_response(response)
        case response.status
        when 200
          JSON.parse(response.body)
        when 400
          error_message = JSON.parse(response.body)['errorMessage']
          raise "Invalid parameters: #{error_message}"
        when 401, 403
          raise 'Invalid API token'
        else
          raise "Creating upload failed with status #{response.status}"
        end
      end

      def self.handle_upload_response(api_token, response, file_path)
        upload_url = response.fetch('uploadURL')
        upload_id = response.fetch('upload_id')

        UI.message('Starting zip file upload')
        upload_file(api_token, upload_url, file_path)
        upload_id
      end

      def self.upload_file(api_token, upload_url, file_path)
        response = Faraday.put(upload_url) do |req|
          req.headers = headers(api_token, nil, 'application/zip')
          req.headers['Content-Length'] = File.size(file_path).to_s
          req.body = Faraday::UploadIO.new(file_path, 'application/zip')
        end

        raise "Uploading zip file failed #{response.status}" unless response.status == 200
      end
    end
  end
end
