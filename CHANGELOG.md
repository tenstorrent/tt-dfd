# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Fixed 

### Changed

### Removed

## [0.2.1] - 2025-11-26

### Fixed

- Read latency for tt_dfd_generic_mem_model reduced to 1 cycle


## [0.2.0] - 2025-10-24

### Added

- Added proper integration guide under [doc/](doc/)
- added missing element in rdl file
- Updated README.md with lint target information
- Added lint waivers for spyglass enhanced lint
- Make cust_rtl support for MacOS (older bash)

### Fixed 

- Fix the read latency cycle in mem_model
- Bug fixes on Sink pointer updates
- Bug fixes on Encoder Priv mode logic, Cleanup code
- Fixed wrap around in FIFO being limited to powers of 2. 
- Fixed te_encoder ignoring inhibitsrc mmr. NTR MMR changes. Added lint targets to make.
- Fixes to trace encoder
- Fixes for cla
- Swap Tval and Tstamp connections that were previously incorrectly set

### Changed

- Parameter NUM_TRACE_INST changed to NUM_TRACE_AND_ANALYZER_INST for better clarity of parameter
- Changed module names for all common cells to have a tt_dfd_ prefix

### Removed

- Removed unused dffs

## [0.1.0] - 2025-09-25

### Added

- Initial release of tt-dfd
- Includes main source RTL, basic testbenches, and some tooling for programming
