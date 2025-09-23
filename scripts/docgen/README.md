# CLA Documentation Generator
This script creates documentation for CLA debug mux inputs and topology. 

## Usage
```
usage: generateClaDoc.py [-h] [--jsonOutputPath JSONOUTPUTPATH]
                         [--csvOutputPath CSVOUTPUTPATH] [--logName LOGNAME]
                         muxCfgPath

Generate CLA debug bus documentation. Extracts bit indexes and debug lanes for
each input signal going into the debug mux.

positional arguments:
  muxCfgPath            Path to the input json file. This specifies paths to
                        the pkg dependencies and the inputs to your debug mux

optional arguments:
  -h, --help            show this help message and exit
  --jsonOutputPath JSONOUTPUTPATH
                        Output path for where debug mux info json will be
                        written
  --csvOutputPath CSVOUTPUTPATH
                        Output path for where debug mux info csv will be
                        written
  --logName LOGNAME     Name of output log file
```

The script will output both a json file and a CSV* file as CLA mux documentation. These specify all the input signals connected to the debug muxe(s), as well as their bit widths, mux lanes,and lane indeces.\
***\*NOTE: The CSV functionality is currently broken due to the addition of nested mux support.***\
The json version of the documentation is used as an input to the CLA compiler.\
This script takes a debug mux config file (json) as an input, which specifies the mux input signals and mux topology (if multiple muxes are nested).\
This script only has to be run once, or when any changes to the mux inputs or topology are made.

## Mux Configuration File
CLA debug muxes are described using a json file.\
Refer to [./example/example_debug_mux_cfg.json](./example/example_debug_mux_cfg.json) for an example.

### Configuration Fields

| Field      | Required? | Description | Legal Values |
| ----------- | ----------- | ----------- | ----------- |
| Package Files | required  | A list of file paths for required verilog packages. Any types or parameters defined in a package that are referenced in the config file must be defined in one of the specifed package files. | \<list(str)\>  |
| Macro Defines | optional  | A list of externally defined compilation flags | \<list(str)\>  |
| CLA Input | required  | Signal name of the final 64b bus that is connected to the CLA debug_signals port. Must be specified as an output of one of the muxes defined in the config file. | \<str\> |
| Debug Mux Instances | required  | Each member of this object describes an instance of a CLA debug mux instance | \<dict\> |

### Debug Mux Instance Fields

| Field      | Required? | Description | Legal Values |
| ----------- | ----------- | ----------- | ----------- |
| DbgMuxSelCsr | required  | Specify the name(s) of the debug mux select register connected to this mux | \<str,list(str)\> |
| LANE_WIDTH | required  | Specify the lane width of this mux. Can either be an integer or a parameter name | \<int,str\> |
| NUM_INPUT_LANES | required  | Specify the number of input lanes this mux has. Can either be an integer or a parameter name | \<int,str\> |
| DEBUG_MUX_ID | required  | Specify the ID of this mux | \<int\> |
| debug_bus_out | required  | Signal name of this mux output | \<str\>  |
| additional_output_stages | optional  | Number of additional flop stages on the output of the mux instance. Defaults to 0. Can either be an integer or a parameter name | \<int,str\>  |
| debug_signals_in | required  | List of inputs of this mux. Each input specifies the name and type of the signal. Inputs must be listed from most to least significant bit. All listed inputs are presumed to have no unused bus bits between them. | \<list(dict)\>  |

Note that parameters, struct, and enum types can be referenced in the config file, so long as they are defined in the specifed package files. The docGen script will parse the specified package files.\
However, the script is not able to automatically find package dependancies. So if package_A::param_A depends on package_B, and you reference param_A or it's dependants in the config file, you must provide the paths to both package_A and package_B in your config file.\
The script will expand structs used as mux inputs, even if they are nested. This allows you to specify entire structs as inputs, rather than specifying each struct field individually in the config file.