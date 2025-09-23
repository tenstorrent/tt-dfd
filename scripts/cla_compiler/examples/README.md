# CLA Compiler Example
This is an example for how to use the CLA compiler script.
| File      | Description |
| ----------- | ----------- |
| example_dfd_cla_program.yaml | File that describes the CLA program. This is an input for the compiler script. |
| example_dfd_debug_bus_info.json | File that describes the CLA debug bus signals. This is an input for the compiler. This file was generated using the [generateClaDoc.py](../../docGen/README.md) script. |
| value_dump.example_dfd_cla_program.yaml | Output of the CLA compiler. Specifies field values for all CLA and mux CSRs |

This example is based on the example DFD RTL used for the docGen script. Refer to [../../docGen/example_dfd/README.md](../../docGen/example_dfd/README.md) for details.

The output file `value_dump.example_cla_program.yaml` was generated using the following command:
```console
python compileClaProgram.py example_dfd_cla_program.yaml --busInfoPath example_dfd_debug_bus_info.json
```