# tt-dfd — Trace & Debug Fabric IP
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Design for Debug (DfD) is a methodology that integrates on-chip instrumentation for enhanced observability and controllability in silicon. These DfD elements enable post-silicon engineers to monitor micro-architectural behavior, capture and store design traces, and trigger specific actions for comprehensive debug and workarounds.

Tenstorrent's tt-dfd is an open-source, parameterizable on-chip DfD IP solution. It provides modular debug and trace capabilities, including:

* Core Logic Analyzer (CLA): For real-time signal and state analysis.

* Debug Signal Trace (DST): To capture a history of user-defined signals.

* N-Trace (Nexus Trace): For instruction-level tracing, based on the Nexus 5001 standard.

These features can be selectively enabled or disabled via configuration parameters to optimize for silicon area, power consumption, and specific integration needs.

## Requirements

Install the following to build and run the included examples:

- [Bender](https://github.com/pulp-platform/bender)
- [make](https://www.gnu.org/software/make/)
- [Python](https://www.python.org/) 3.9.6+
  - [PyYAML](https://pypi.org/project/PyYAML/)
- Simulator: The provided [Makefile](Makefile) targets use Synopsys VCS. Other simulators may work with minor changes to the compile/run lines.

## Integration 

The following information is useful for those who would like to include tt-dfd in their own projects.

- [Parameters](#top-level-parameters)
- [Repository layout](#repository-layout)
- [Register map](#register-map-mmrs)
- [CLA tooling](#cla-tooling)
- [Filelist](#filelist)


### Top-level parameters 

These parameters are available to be modified by users who instantiate tt-dfd via the [dfd_top](rtl/dfd/dfd_top.sv) module. See the section below on [building custom variants](#build-custom-variants) for generating and using trimmed top variants.

| Parameter             | Type              | Default | Description |
| ---                   | ---               | ---     | ---         |
| NUM_TRACE_INST        | int unsigned      | 1 | Number of trace/CLA/N-Trace/DST instances to instantiate. |
| NTRACE_SUPPORT        | bit               | 1 | Set to 1'b1 to enable N-Trace features, otherwise disable and tie off related blocks |
| DST_SUPPORT           | bit               | 1 | Set to 1'b1 to enable DST features, otherwise disable and tie off related blocks |
| CLA_SUPPORT           | bit               | 1 | Set to 1'b1 to enable CLA features, otherwise disable and tie off related blocks |
| INTERNAL_MMRS         | bit               | 1 | Set to 1'b1 to use internal MMR/CSR block; when 0, use external MMR interface ports. __NOTE: Only INTERNAL_MMRS = 1 is supported at the moment__|
| DEBUGMARKER_WIDTH     | int unsigned      | 8 | Sets the width of `cla_debug_marker`. __NOTE: Output enabled only when CLA_SUPPORT = 1__ |
| TRC_SIZE_IN_KB        | int unsigned      | 16| Trace sink size in KiB (derives `TRC_SIZE_IN_B` and `TRC_RAM_INDEX`). __NOTE: Trace sink is only available when DST_SUPPORT = 1 OR NTRACE_SUPPORT = 1__|
| TSEL_CONFIGURABLE     | bit               | 0 | Enable support for test select (TSEL) capabilities on trace sink memory cells. By default, this is not used by the generic memory model. This has been exposed so that users may modify the `dfd_trace_mem_sink_generic.sv` file to suit their own memory model needs. |
| SINK_CELL             | mem_gen_pkg::MemCell_e | mem_gen_pkg::mem_cell_undefined | Trace sink memory cell type (technology-specific). By default, this is not used by the generic memory model. This has been exposed so that users may modify the `dfd_trace_mem_sink_generic.sv` file to suit their own memory model needs. |
| BASE_ADDR             | bit [DFD_APB_ADDR_WIDTH-1:0] | 0 | Base APB address for internal MMR/CSR block. |
| TIMESYNC_ADDR_OFFSET  | bit [DFD_APB_ADDR_WIDTH-1:0] | 'h200 | Start offset for per-instance timesync MMRs. __NOTE: Timesync is only enabled when CLA_SUPPORT = 1__ |

Notes:
- Types and widths such as `DFD_APB_ADDR_WIDTH` come from packages imported by [dfd_top](rtl/dfd/dfd_top.sv).
- When instantiating [dfd_top](rtl/dfd/dfd_top.sv) instances with certain features disabled, please tie off inputs to 0 to avoid lint/compilation issues. If you would like to avoid generating the I/O of disabled features altogether, please see [building custom variants](#build-custom-variants). 

### Repository layout

| Top directory         | Subdirectory       | Description |
| ---                   | ---                    | ---         |
| [rtl/](rtl)           | [cla/](rtl/cla)         | Core Logic Analyzer (CLA) modules for debug signal monitoring and triggering |
|                       | [common/](rtl/common)   | Generic RTL components and utilities (FIFOs, flip-flops, muxes, memory models) |
|                       | [dfd/](rtl/dfd)         | Main Dft top-level modules and core infrastructure |
|                       | [gen_files/](rtl/gen_files) | Auto-generated custom top-level variants with feature-specific I/O pruning |
|                       | [intf/](rtl/intf)       | Interface struct definitions and packages |
|                       | [mmr/](rtl/mmr)         | Memory-mapped registers (CSRs) and register definition files |
|                       | [trace/](rtl/trace)     | Trace infrastructure including packetizers, encoders, and trace networks |
| [dv/](dv)             | [dfd/](dv/dfd)          | Testbenches, verification code, and APB traffic generation utilities |
| [scripts/](scripts)   | [cla_compiler/](scripts/cla_compiler) | [CLA programming tools](scripts/cla_compiler/README.md) and example programs |
|                       | [cust_rtl/](scripts/cust_rtl) | Scripts for generating custom RTL variants |
|                       | [docgen/](scripts/docgen) | [Documentation generation tools](scripts/docgen/README.md) and example programs

### Register map (MMRs)

tt-dfd exposes internal memory-mapped registers (MMRs) for control and status. The CSR definitions live under [rtl/mmr/](rtl/mmr/). 

### CLA tooling

tt-dfd provides the following tools to ease and simplify the CLA programming flow. 

- [CLA DocGen](scripts/docgen/): generates documentation for CLA muxes from a JSON description (inputs, widths, topology).
- [CLA Compiler](scripts/cla_compiler/): builds a CLA programming sequence from the mux documentation JSON (created by DocGen) and a CLA program YAML.

After producing a value-dump YAML of MMR fields to program, you can generate an APB write script with:

```bash
# Generate APB write script from CLA Compiler output
$ python3 dv/dfd/yamlToApbTraffic.py <path/to/value_dump.yaml> -o apb_write.txt
```

Users are encouraged to use the tools above to program the CLA. Both CLA DocGen and the CLA Compiler contain READMEs with examples for each tool.  

### Filelist

This repository uses [Bender](https://github.com/pulp-platform/bender) to manage sources and dependencies. Performing a `make build` will automatically regenerate the filelist via Bender. However, users may also regenerate the filelist themselves by using the following command.

```bash
# Generate the filelist using Bender
$ make tt_dfd.f
```

In addition to all the files contained in this repository, this project sources dependencies from an open-source repository for [AXI](https://github.com/pulp-platform/axi.git) IP. Bender will automatically populate the directory with the required files and generate the complete filelist that can be used.   

## Testbench

tt-dfd provides some testbenches alongside simple tests to check for basic functionality. More complex and complete tests will be provided in the future. 

In order to run the tests, follow the steps below:

### Build

To run tests and/or generate the filelist for tt-dfd, follow the steps below to build the repository. 

```bash
# Clone the repository
$ git clone https://github.com/tenstorrent/tt-dfd.git

# Enter the tt-dfd repository 
$ cd tt-dfd

# Run make build
$ make build
```

This produces `tt_dfd.f`, which is used by the included test flow and can be consumed by your own simulator or synthesis flow.

#### Build custom variants

As part of the build flow, `make build` preprocesses the top-level file and generates trimmed-top variants of [dfd_top](rtl/dfd/dfd_top.sv) with pruned I/O depending on the included features. Although the standard top-level file can be used with build-time parameters enabled or disabled, users may opt to use the custom top variants found in the [gen_files](rtl/gen_files/) directory for cleaner integration.   

Users may also perform the custom-variant generation as a standalone step using the command below.

```bash
# Generate custom variant top files
$ make cust_rtl
```

Custom variants are named `dfd_top_*.sv` where one or more of the following suffixes are included in the name, indicating that the variant includes the feature.

* cla : variant supports CLA 
* dst : variant supports DST
* ntrace : variant supports N-Trace
* mmr : variant uses internal MMRs/CSRs for configuration (__external MMRs/CSRs are currently not supported__)

### Running tests

After completing the above build steps, users may run the following commands to execute included tests. The [Makefile](Makefile) assumes that VCS is installed. 

The default [Makefile](Makefile) uses Synopsys VCS. If you use a different simulator, update the compile/run lines accordingly.

```bash
# Run all tests 
$ make tests

# Run top test which checks for correct connections and syntax errors
$ make top_test

# Run APB test that writes and reads back configuration MMRs and checks for errors
$ make apb_test 
```
