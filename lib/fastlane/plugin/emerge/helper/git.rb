require 'fastlane_core/print_table'
require 'open3'

module Fastlane
  module Helper
    module Git
      def self.branch
        shell_command = "git rev-parse --abbrev-ref HEAD"
        UI.command(shell_command)
        stdout, _, status = Open3.capture3(shell_command)
        unless status.success?
          UI.error("Failed to get the current branch name")
          return nil
        end

        branch_name = stdout.strip
        if branch_name == "HEAD"
          # We're in a detached HEAD state
          # Find all branches that contains the current HEAD commit
          #
          # Example output:
          # * (HEAD detached at dec13a5)
          # telkins/detached-test
          # remotes/origin/telkins/detached-test
          #
          # So far I've seen this output be fairly stable, so take the second line
          shell_command = "git branch -a --contains HEAD | sed -n 2p | awk '{ printf $1 }'"
          UI.command(shell_command)
          head_stdout, _, head_status = Open3.capture3(shell_command)

          unless head_status.success?
            UI.error("Failed to get the current branch name for detached HEAD")
            return nil
          end

          branch_name = head_stdout.strip
        end

        branch_name == "HEAD" ? nil : branch_name
      end

      def self.sha
        shell_command = "git rev-parse HEAD"
        UI.command(shell_command)
        stdout, _, status = Open3.capture3(shell_command)
        stdout.strip if status.success?
      end

      def self.base_sha
        current_branch = branch
        remote_head = remote_head_branch
        return nil if current_branch.nil? || remote_head.nil?

        shell_command = "git merge-base #{remote_head} #{current_branch}"
        UI.command(shell_command)
        stdout, _, status = Open3.capture3(shell_command)
        return nil if stdout.strip.empty? || !status.success?
        current_sha = sha
        stdout.strip == current_sha ? nil : stdout.strip
      end

      def self.primary_remote
        remote = remote()
        return nil if remote.nil?
        remote.include?("origin") ? "origin" : remote.first
      end

      def self.remote_head_branch(remote = primary_remote)
        return nil if remote.nil?
        shell_command = "git remote show #{remote}"
        UI.command(shell_command)
        stdout, _, status = Open3.capture3(shell_command)
        return nil if stdout.nil? || !status.success?
        stdout
          .split("\n")
          .map(&:strip)
          .find { |line| line.start_with?("HEAD branch: ") }
          &.split(' ')
          &.last
      end

      def self.remote_url(remote = primary_remote)
        return nil if remote.nil?
        shell_command = "git config --get remote.#{remote}.url"
        UI.command(shell_command)
        stdout, _, status = Open3.capture3(shell_command)
        stdout if status.success?
      end

      def self.remote
        shell_command = "git remote"
        UI.command(shell_command)
        stdout, _, status = Open3.capture3(shell_command)
        stdout.split("\n") if status.success?
      end
    end
  end
end
