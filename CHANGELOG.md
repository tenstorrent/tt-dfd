# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `TRACE_SUPPORT` parameter to `dfd_top` and `dfd_mmrs` to decouple the trace subsystem (and its trace MMRs) from `DST_SUPPORT`/`NTRACE_SUPPORT`.
- Added new `_notrace` variants which don't include the trace network sink or funnel; the trace subsystem is instantiated externally and the core-facing trace-network (TNIF) interface is exposed on the module boundary as `tnif_*` ports.
- Added new `_tnif` variants (e.g. `dfd_top_tnif`, `dfd_top_cla_tnif`) which contain only the trace network/funnel/mem with the DST/NTRACE encoders external. The TNIF ports are derived from `TRACE_SUPPORT & !(DST_SUPPORT || NTRACE_SUPPORT)` and are commented out in the template, exposed only when the `_tnif` variant is generated.
- Added [dv/dfd/dfd_tnif_tb.sv](dv/dfd/dfd_tnif_tb.sv) connecting a `dfd_top_cla_ntrace_notrace_mmr` (trace sources) to a `dfd_top_tnif` (trace network) over the TNIF boundary to validate the split topology.

### Fixed 

- Fixed Spyglass `W123` ("read but never set") for `debug_bus_aligned` in non-CLA variants by adding a passthrough assignment.

### Changed

- All generated `dfd_top` variants are now MMR-enabled; [scripts/cust_rtl/process_all.sh](scripts/cust_rtl/process_all.sh) enumerates the explicit set of valid variants instead of every feature combination.

### Removed

- Removed generation of non-MMR `dfd_top` variants (including the standalone `dfd_top_mmr`/`dfd_top_cla_mmr`), which were unsupported.

## [0.2.3] - 2026-06-03

### Added

- Added DST decoder under [scripts/dstdecoder](scripts/dstdecoder/). This tool can be used to decode the compressed DST packets back to the original traced data

### Fixed 

- Fixed copyright year to 2026

## [0.2.2] - 2026-05-27

### Added

- Added new section under [README.md](README.md) to reference integration guide and architecture documentation 

### Fixed 

- Fixed DC elaboration issue in dfd_cross_connect.sv with loop var i
- Fixed PARAMETER NUM_TRACE_AND_ANALYZER_INST to allow support for ODD values without throwing error on EDA toosl (caught in [Issue #21](https://github.com/tenstorrent/tt-dfd/issues/21))

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
