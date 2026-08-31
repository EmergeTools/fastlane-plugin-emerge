# Changelog

## 0.11.0

- Upgrade Faraday to `>= 2.14.1, < 3.0`.
- Stream archive uploads to avoid loading the entire file into memory.
- Require Ruby 3.0 or newer.

## 0.10.4

- Adds extra logging for which `file_path` is chosen.
- Add better Git support for detached HEAD states.

## 0.9.0

- Adds a new `emerge_snapshot()` action to build and upload an archive for snapshot testing on Emerge.

## 0.8.0

- Automatically populate various Git fields if they are not provided (`sha`, `base_sha`, `branch`, `pr_number`, `repo_name`).

## 0.7.0

- Renamed the `build_type` field to `tag`.
