# tt-dfd — Trace & Debug Fabric IP

Design for debug (dfd) is the practice of building observability and controllability into silicon and systems from day one. It enables post-silicon engineers to see internal behavior, coordinate capture across blocks, and act on issues without invasive rework.

tt-dfd is an open-source parameterizable on-chip debug and trace IP solution to various dfd needs. It supports multi-CLA (Core Logic Analyzer), DST, and NTRACE, in addition to a trace funnel and trace sinks. Features can be enabled or disabled via parameters to fit your integration needs.


## Repository layout

- `rtl/`: synthesizable RTL sources
- `dv/`: simple DV testbenches and associated files
- `scripts/`: tooling for CLA compiler, DocGen, and utilities
- `Bender.yml`: source list and dependency manifest used to generate file lists

## Requirements

Install the following to build and run the included examples:

- Bender: `https://github.com/pulp-platform/bender`
- make
- Python 3.9.6+
  - PyYAML
- Simulator: the provided `Makefile` targets use Synopsys VCS. Other simulators may work with minor changes to the compile/run lines.

## Build

Build custom RTL variants and update file lists:

```bash
make build
```

This produces `tt_dfd.f`, which can be consumed by your simulator or synthesis flow.

### Build custom variants

`dfd_top.sv` is highly configurable via parameters. For convenience, helper targets generate trimmed-top variants with pruned I/O for cleaner integration:

```bash
make cust_rtl
```

This generates one `.sv` top per feature combination. Note: while permutations with `INTERNAL_MMRS == 0` may be generated, the current release only supports builds with `INTERNAL_MMRS == 1`.

## Register map (MMRs)

tt-dfd exposes internal memory-mapped registers (MMRs) for control and status. The CSR definitions live under `rtl/mmr/`. The APB access behavior is exercised in `dv/dfd/dfd_mmrs_tb.sv`.

## File lists with Bender

This repository uses Bender to manage sources and dependencies. To refresh dependencies and regenerate the file list:

```bash
make tt_dfd.f
```

If you are using this project outside of the original development environment, you may need to update dependency URLs in `Bender.yml` to publicly accessible repositories providing the required packages (e.g., AXI, common cells).

## CLA tooling

The `scripts/` directory contains:

- CLA DocGen: generates documentation for CLA muxes from a JSON description (inputs, widths, topology)
- CLA Compiler: builds a CLA programming sequence from the mux documentation JSON and a CLA program YAML

After producing a value-dump YAML of MMR fields to program, you can generate an APB write script with:

```bash
python3 dv/dfd/yamlToApbTraffic.py <path/to/value_dump.yaml> -o apb_write.txt
```

## Running tests

Two simple tests are provided:

```bash
make tests        # runs both tests
make top_test     # basic compile/elab/heartbeat
make apb_test     # APB read/write of MMRs
```

Notes:
- The default `Makefile` uses Synopsys VCS. If you use a different simulator, update the compile/run lines accordingly.

## Contributing

Issues and pull requests are welcome. Please include tool versions and a minimal reproduction when reporting problems.
