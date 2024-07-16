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
    class EmergeAction < Action
      def self.run(params)
        api_token = params[:api_token]
        file_path = params[:file_path] || lane_context[SharedValues::XCODEBUILD_ARCHIVE]

        if file_path.nil?
          file_path = Dir.glob("#{lane_context[SharedValues::SCAN_DERIVED_DATA_PATH]}/Build/Products/Debug-iphonesimulator/*.app").first
        end
        git_params = Helper::EmergeHelper.make_git_params
        pr_number = params[:pr_number] || git_params.pr_number
        branch = params[:branch] || git_params.branch
        sha = params[:sha] || params[:build_id] || git_params.sha
        base_sha = params[:base_sha] || params[:base_build_id] || git_params.base_sha
        repo_name = params[:repo_name] || git_params.repo_name
        gitlab_project_id = params[:gitlab_project_id]
        tag = params[:tag]
        order_file_version = params[:order_file_version]
        config_path = params[:config_path]

        if file_path.nil? || !File.exist?(file_path)
          UI.error("Invalid input file")
          return
        end
        extension = File.extname(file_path)

        # If the user provided a .app we will look for dsyms and package it into a zipped xcarchive
        if extension == '.app'
          absolute_path = Pathname.new(File.expand_path(file_path))
          UI.message("A .app was provided, dSYMs will be looked for in #{absolute_path.dirname}")
          Dir.mktmpdir do |d|
            application_folder = "#{d}/archive.xcarchive/Products/Applications/"
            dsym_folder = "#{d}/archive.xcarchive/dSYMs/"
            FileUtils.mkdir_p(application_folder)
            FileUtils.mkdir_p(dsym_folder)
            if params[:linkmaps] && params[:linkmaps].length > 0
              linkmap_folder = "#{d}/archive.xcarchive/Linkmaps/"
              FileUtils.mkdir_p(linkmap_folder)
              params[:linkmaps].each do |l|
                FileUtils.cp(l, linkmap_folder)
              end
            end
            Helper::EmergeHelper.copy_config(config_path, "#{d}/archive.xcarchive")
            FileUtils.cp_r(file_path, application_folder)
            copy_dsyms("#{absolute_path.dirname}/*.dsym", dsym_folder)
            copy_dsyms("#{absolute_path.dirname}/*/*.dsym", dsym_folder)
            Xcodeproj::Plist.write_to_path({ "NAME" => "Emerge Upload" }, "#{d}/archive.xcarchive/Info.plist")
            file_path = "#{absolute_path.dirname}/archive.xcarchive.zip"
            ZipAction.run(
              path: "#{d}/archive.xcarchive",
              output_path: file_path,
              exclude: [],
              include: []
            )
            UI.message("Archive generated at #{file_path}")
          end
        elsif extension == '.xcarchive'
          zip_path = file_path + ".zip"
          if params[:linkmaps] && params[:linkmaps].length > 0
            linkmap_folder = "#{file_path}/Linkmaps/"
            FileUtils.mkdir_p(linkmap_folder)
            params[:linkmaps].each do |l|
              FileUtils.cp(l, linkmap_folder)
            end
          end
          Helper::EmergeHelper.copy_config(config_path, file_path)
          Actions::ZipAction.run(
            path: file_path,
            output_path: zip_path,
            exclude: [],
            include: []
          )
          file_path = zip_path
        elsif (extension == '.zip' || extension == '.ipa') && params[:linkmaps] && params[:linkmaps].length > 0
          UI.error("Provided #{extension == '.zip' ? 'zipped archive' : 'ipa'} and linkmaps, linkmaps will not be added to upload.")
        elsif extension != '.zip' && extension != '.ipa'
          UI.error("Invalid input file")
          return
        end

        params = {
          prNumber: pr_number,
          branch: branch,
          sha: sha,
          baseSha: base_sha,
          repoName: repo_name,
          gitlabProjectId: gitlab_project_id,
          orderFileVersion: order_file_version,
          appIdSuffix: params[:app_id_suffix],
          tag: tag || "default"
        }
        upload_id = Helper::EmergeHelper.perform_upload(api_token, params, file_path)
        UI.success("🎉 Your app is processing, you can find the results at https://emergetools.com/build/#{upload_id}")
      end

      def self.copy_dsyms(from, to)
        Dir.glob(from) do |filename|
          UI.message("Found dSYM: #{Pathname.new(filename).basename}")
          FileUtils.cp_r(filename, to)
        end
      end

      def self.description
        "Fastlane plugin for Emerge"
      end

      def self.authors
        ["Emerge Tools"]
      end

      def self.return_value
        "If successful, returns the upload id of the generated build"
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
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       env_name: "EMERGE_FILE_PATH",
                                       description: "Path to the zipped xcarchive or app to upload",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :linkmaps,
                                       description: "List of paths to linkmaps",
                                       optional: true,
                                       type: Array),
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
          FastlaneCore::ConfigItem.new(key: :build_id,
                                       description: "A string to identify this build",
                                       deprecated: "Replaced by `sha`",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :base_build_id,
                                       description: "Id of the build to compare with this upload",
                                       deprecated: "Replaced by `base_sha`",
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
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :order_file_version,
                                       description: "Version of the order file to download",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :config_path,
                                       description: "Path to Emerge config path",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :app_id_suffix,
                                       description: "A suffix to append to the application ID to differentiate between different builds of the same app",
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
