require 'open3'

module Fastlane
  module Helper
    module Git
      def self.branch
        stdout, _, status = Open3.capture3("git rev-parse --abbrev-ref HEAD")
        stdout.strip if status.success?
      end

      def self.sha
        stdout, _, status = Open3.capture3("git rev-parse HEAD")
        stdout.strip if status.success?
      end

      def self.base_sha
        stdout, _, status = Open3.capture3("git merge-base #{remote_head_branch} #{branch}")
        return nil if stdout.strip.empty? || !status.success?
        stdout.strip
      end

      def self.primary_remote
        remote = remote()
        return nil if remote.nil?
        remote.include?("origin") ? "origin" : remote.first
      end

      def self.remote_head_branch(remote = primary_remote)
        return nil if remote.nil?
        show = system("git remote show #{remote}")
        return nil if show.nil?
        show
          .split("\n")
          .map(&:strip)
          .find { |line| line.start_with?("HEAD branch: ") }
          &.split(' ')
          &.last
      end

      def self.remote_url(remote = primary_remote)
        return nil if remote.nil?
        system("git config --get remote.#{remote}.url")
      end

      def self.remote
        system("git remote")&.split("\n")
      end
    end
  end
end
