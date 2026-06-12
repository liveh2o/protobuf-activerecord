All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Protobuf Active Record adheres to a shifted version of [semver](https://semver.org/spec/v2.0.0.html)
(a la Rails): major/minor versions shadow Rails [versions](https://guides.rubyonrails.org/maintenance_policy.html#versioning)
since it depends on specific Rails versions.

## [Unreleased]

- Added Rails 7.2 support; ActiveRecord/ActiveSupport dependency widened to `>= 7.1, < 7.3`.
- Bumped minimum Ruby to 3.1 (required by Rails 7.2).
- Added Appraisal-based test matrix for Rails 7.1 and 7.2.

## [7.0.0] – 2024-03-03

- Added Rails 7.0 support

## [7.1.1] – 2026-03-16

- Change clear_active_connections! to include handler.
