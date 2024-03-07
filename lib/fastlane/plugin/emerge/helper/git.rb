module Fastlane
  module Helper
    module Git
      def self.branch
        system("git rev-parse --abbrev-ref HEAD").strip
      end

      def self.sha
        system("git rev-parse HEAD").strip
      end

      def self.base_sha
        base_sha = system("git merge-base #{remote_head_branch} #{branch}")
        return nil if base_sha.strip.empty?
        base_sha
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
