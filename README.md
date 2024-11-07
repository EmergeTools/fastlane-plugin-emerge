# Emerge `fastlane` plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-emerge)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-emerge`, add it to your project by running:

```bash
fastlane add_plugin emerge
```

## About Emerge

[Emerge](https://emergetools.com) offers a suite of products to help optimize app size, performance and quality. This plugin provides a set of actions to interact with the Emerge API.

## Usage

### API Token

First obtain an [API token](https://docs.emergetools.com/docs/uploading-basics#obtain-an-api-key) for your organization. The API Token is used to authenticate with the Emerge API in each call. Our actions will automatically pick up the API key if configured as an `EMERGE_API_TOKEN` environment variable.

### Size Analysis

```ruby
platform :ios do
  lane :emerge_upload do
    # Tip: group builds in our dashboard via the `tag` parameter
    emerge(tag: 'pr_build')
  end
end
```

1. Produce a build using `gym()`, `run_tests()`, or other Fastlane actions
2. When you are ready to upload to Emerge, simply call the `emerge()` action
    - a. We will automatically detect the most recently built app to upload, or you can manually pass in a `file_path` parameter

For a full list of available parameters run `fastlane action emerge`.

### Snapshot Testing

Emerge Snapshot Testing works by parsing Xcode Previews _from the app binary_. This means the upload to Emerge's service needs to include Previews as part of the app code. There are a couple ways to do this:

#### Re-use a unit test build with the `emerge()` action

If you're already running unit tests with fastlane, simply call the `emerge()` action after running unit tests to automatically upload the unit test build to Emerge. The action will detect the build generated for unit tests, or the `file_path` param can be explicitly set. Generally this build is a Debug build and should have Previews code included.

#### Generate a new build with the `emerge_snapshot()` action

This will build the app from scratch with recommended configurations to prevent Previews from being removed/stripped, and then upload the built app to Emerge.

```ruby
platform :ios do
  lane :snapshot_testing do
    # Call the `emerge_snapshot()` action with the respective scheme for
    # us to build. We will generate a build with the recommended settings
    # and upload to Emerge's API.
    emerge_snapshot(scheme: 'Hacker News')
  end
end
```

For a full list of available parameters run `fastlane action emerge_snapshot`.

## Git Configuration

For build comparisons to work, Emerge needs the appropriate Git `sha` and `base_sha` values set on each build. Emerge will automatically compare a build at `sha` against the build we find matching the `base_sha` for a given application id. We also recommend setting `pr_number`, `branch`, `repo_name`, and `previous_sha` for the best experience.

For example:

- `sha`: `pr-branch-commit-2`
- `base_sha`: `main-branch-commit-1`
- `previous_sha`: `pr-branch-commit-1`
- `pr_number`: `42`
- `branch`: `my-awesome-feature`
- `repo_name`: `EmergeTools/hackernews`

Will compare the size difference of your pull request changes.

This plugin will automatically configure Git values for you assuming certain Github workflow triggers:

```yaml
on:
  # Produce base builds with a 'sha' when commits are pushed to the main branch
  push:
    branches: [main]

  # Produce branch comparison builds with `sha` and `base_sha` when commits are pushed
  # to open pull requests
  pull_request:
    branches: [main]

  ...
```

If this doesn't cover your use-case, manually set the `sha` and `base_sha` values when calling the Emerge plugin.

## Issues and Feedback

For any other issues and feedback about this plugin, please open a [GitHub issue](https://github.com/EmergeTools/fastlane-plugin-emerge/issues).

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
