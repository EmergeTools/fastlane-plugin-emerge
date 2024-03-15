require 'fastlane/action'
require 'fastlane_core/print_table'
require_relative '../helper/emerge_helper'
require_relative '../helper/git'
require_relative '../helper/github'
require 'pathname'
require 'tmpdir'
require 'json'
require 'fileutils'

module Fastlane
  module Actions
    class EmergeSnapshotAction < Action
      def self.run(params)
        api_token = params[:api_token]

        git_params = Helper::EmergeHelper.make_git_params
        pr_number = params[:pr_number] || git_params.pr_number
        branch = params[:branch] || git_params.branch
        sha = params[:sha] || git_params.sha
        base_sha = params[:base_sha] || git_params.base_sha
        repo_name = params[:repo_name] || git_params.repo_name
        gitlab_project_id = params[:gitlab_project_id]
        tag = params[:tag]
        config_path = params[:config_path]
        scheme = params[:scheme]
        configuration = params[:configuration]
        team_id = params[:team_id] || CredentialsManager::AppfileConfig.try_fetch_value(:team_id)

        Dir.mktmpdir do |temp_dir|
          archive_path = "#{temp_dir}/build/snapshot.xcarchive"
          other_action.gym(
            scheme: scheme,
            configuration: configuration,
            skip_codesigning: true,
            clean: true,
            export_method: "development",
            export_team_id: team_id,
            skip_package_ipa: true,
            output_directory: "#{temp_dir}/build",
            archive_path: archive_path
          )

          Helper::EmergeHelper.copy_config(config_path, archive_path)
          Xcodeproj::Plist.write_to_path({ "NAME" => "Emerge Upload" }, "#{archive_path}/Info.plist")

          zip_file_path = "#{temp_dir}/build/archive.xcarchive.zip"
          ZipAction.run(
            path: archive_path,
            output_path: zip_file_path,
            exclude: [],
            include: []
          )

          params = {
            appIdSuffix: 'snapshots',
            prNumber: pr_number,
            branch: branch,
            sha: sha,
            baseSha: base_sha,
            repoName: repo_name,
            gitlabProjectId: gitlab_project_id,
            tag: tag || "default"
          }
          upload_id = Helper::EmergeHelper.perform_upload(api_token, params, zip_file_path)
          UI.success("🎉 Your app is processing, you can find the results at https://emergetools.com/snapshot/#{upload_id}")
        end
      end

      def self.description
        "Fastlane plugin for Emerge to generate iOS snapshots"
      end

      def self.authors
        ["Emerge Tools"]
      end

      def self.return_value
        "If successful, returns the upload id of the generated snapshot build"
      end

      def self.details
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "EMERGE_API_TOKEN",
                                       description: "An API token for Emerge",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       description: "The scheme of your app to build",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :configuration,
                                       description: "The configuration of your app to use",
                                       optional: false,
                                       default_value: "Debug",
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       env_name: "EXPORT_TEAM_ID",
                                       description: "The Apple Team ID to use for exporting the archive. If not provided, we will try to use the team_id from the Appfile",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :config_path,
                                       description: "Path to Emerge YAML config path",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :pr_number,
                                       description: "The PR number that triggered this upload",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       description: "The current git branch",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :sha,
                                       description: "The git SHA that triggered this build",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :base_sha,
                                       description: "The git SHA of the base build",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :repo_name,
                                       description: "Full name of the respository this upload was triggered from. For example: EmergeTools/Emerge",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :gitlab_project_id,
                                       description: "Id of the gitlab project this upload was triggered from",
                                       optional: true,
                                       type: Integer),
          FastlaneCore::ConfigItem.new(key: :tag,
                                       description: "String to label the build. Useful for grouping builds together in our dashboard, like development, default, or pull-request",
                                       optional: true,
                                       type: String)
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
