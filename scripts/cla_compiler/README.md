# CLA Program Compiler
This script compiles an abstract description of a CLA program into csr register values. This makes programming the CLA easier and less error-prone, since you do not need to manually calculate mux selects, match, or mask CSRs.

## Usage
```
compileClaProgram.py [-h] [--busInfoPath BUSINFOPATH]
                     [--outputPath OUTPUTPATH] [--logName LOGNAME]
                     [--mmrSpecPath MMRSPECPATH]
                     [--claBaseAddress CLABASEADDRESS] [--numCla NUMCLA]
                     [--debugBusWidth {64,128}]
                     programPath

Compile CLA program description into CSR field values

positional arguments:
  programPath           Path to the yaml file that describes the desired CLA
                        program

optional arguments:
  -h, --help            show this help message and exit
  --busInfoPath BUSINFOPATH
                        Path to the json file that contains information on the
                        debug bus implementation. This json can be generated
                        using generateClaDoc.py
  --outputPath OUTPUTPATH
                        Output path for where CSR fields will be dumped in a
                        yaml file
  --logName LOGNAME     Name of output log file
  --mmrSpecPath MMRSPECPATH
                        Path to the CLA MMR spec yaml. Provides the register
                        offsets. The reset value of c_dbg_version is checked
                        for compatibility (only v2.x is supported)
  --claBaseAddress CLABASEADDRESS
                        Address of the first CLA instance (CLA instance 0).
                        Can be calculated with claBaseAddress.sh. Default: 0x0
  --numCla NUMCLA       Number of CLA instances. The program is compiled for
                        every instance, with the instances placed contiguously
                        (0x1000 apart) from claBaseAddress. Default: 1
  --debugBusWidth {64,128}
                        Width of the CLA debug bus input. Default: 128
```

The script will output the CSR register values into a yaml file (and a csv file with the same content). The compiler targets the CLA MMR v2.x spec ([../../rtl/mmr/spec/cla_mmrs.yml](../../rtl/mmr/spec/cla_mmrs.yml)). Register names are the spec register names, and 128b debug bus values (match/mask, transition, ones count, any change, compare) are split over a `_lo` and a `_hi` register.\
This file will also have comments to help you relate the compiled values to the original program description.\
Example program: [examples/README.md](examples/README.md)

### Output format
The program is compiled for every CLA instance (`--numCla`). Each instance lists all of its registers with their absolute address (instance base + the register offset from the MMR spec), the individual field values and the value of the entire 64 bit register:
```yaml
cla0:
  base_address: 0x3000
  registers:
    c_dbg_node0_eap0:  # NODE_0.EXAMPLE_ALWAYS
      address: 0x3120
      fields:
        ...
      value: 0x...
cla1:
  base_address: 0x4000
  ...
```
The csv has the columns `instance,mmr_name,address,hex_value`.

Notes:
* The compiler checks that the bit ranges of the fields it programs match the MMR spec, and fails if they do not.
* All debug mux instances share the single `c_dbg_mux_sel_lo`/`c_dbg_mux_sel_hi` register pair. The mux a write applies to is chosen by its `DbmId`, so the registers of the mux instances are listed as `c_dbg_mux_sel_lo__ID_<n>` (same address). Write them in order. For each mux, write the `_hi` register (only present when the mux has more than 8 output lanes) before the `_lo` register: the select values are only latched when `Valid` (in the `_lo` register) is written. Every 64-bit register is accessed as two 4-byte aligned 32-bit words and must be written high word (address + 4) first, then low word (address); `dv/dfd/yamlToApbTraffic.py` emits them in this order.
* Instances are placed 0x1000 apart, which matches how the CLA, DST and NTrace instances are laid out in the DFD MMR space.

### CLA base address
The MMR space of the DFD is laid out in the following order: DST Sink, NTR Sink, Funnel, CLA, DST, NTR. DST Sink, NTR Sink and Funnel take one 0x1000 window each (if present), and each CLA/DST/NTrace instance takes one 0x1000 window. The CLA base address therefore depends on the MMR base address and on which of the DST Sink/NTR Sink/Funnel are present:
```
CLA base = MMR_BASE_ADDRESS + 0x1000 * (DST_SINK_PRESENT + NTR_SINK_PRESENT + FUNNEL_PRESENT)
```
[claBaseAddress.sh](claBaseAddress.sh) calculates this (and the DST/NTR start addresses):
```console
$ ./claBaseAddress.sh -b 0x10000 -n 0 -c 4     # MMR base 0x10000, no NTR Sink, 4 CLAs
CLA_BASE_ADDRESS=0x12000
...
$ python compileClaProgram.py prog.yaml --claBaseAddress $(./claBaseAddress.sh -q -b 0x10000 -n 0) --numCla 4
```
Run `./claBaseAddress.sh -h` for all options.

## CLA Program Description
CLA programs are described using a yaml file.\
Program format example:
```yaml
#Define counters
COUNTERS:
  # A list of strings used for counter aliases. Allows you to use custom counter names rather than CLA_COUNTER_X. 
  # These counter names can be arbitrary strings with no internal whitespace
  - MY_REQUEST_COUNTER
  - MY_OTHER_COUNTER

#Define custom action opcodes
CUSTOM_ACTIONS:
  # A set of custom action opcode aliases. Allows you to use these action names rather than explicity defining opcode values.
  CUSTOM_ACTION_FOO: 0x0
  CUSTOM_ACTION_BAR: 0x1

#Define EAPs
START_NODE: MY_INITIAL_NODE  #tells the compiler which node should be assigned to Node 0 (initial state)
NODES:
  # Each member of the NODES object is a CLA node. Each of these nodes can contain up to 4 event action pairs (EAPs)
  # The names of these nodes can be arbitrary
  MY_INITIAL_NODE:
    # Each member of a node object is an EAP object
    # The names of the EAPs can be arbitrary
    MY_EAP_DETECT_REQ_RESP:
      debug_mux_reg: dbg_mux_control_A  # Specify the name of the debug mux register to use for this CSR (some units have multiple registers)

      event_triggers:                   
        # Each member of the event_triggers field is an event. Up to 3 events can be specified. The event names can be arbitrary, but must be unique
        myEvent_A:
          # List of strings that specify the conditions required for this event. Multiple conditions can be specified.
          - request_valid == 1
          - request_ready == 1
        myEvent_B:
          # List of strings that specify the conditions required for this event
          - posedge response_valid
        myEvent_C:
          # List of strings that specify the conditions required for this event
          - XTRIGGER_0

      event_logical_op: (myEvent_A && (!myEvent_B)) || myEvent_C     # Logical expression between the events needed to trigger the EAP. Both Verilog and Python syntax are supported

      actions: 
        # List of actions to take when the EAP is triggered. Up to 4 actions can be specified
        # These actions can either be strings or opcode values (int or hex)
        - INCREMENT MY_REQUEST_COUNTER
      custom_actions: 
        # List of custom actions to take when the EAP is triggered. Up to 2 custom actions can be specified
        # These actions can either be strings (opcode aliases) or opcode values (int or hex)
        - CUSTOM_ACTION_FOO
        - 0x1  #equivalent to "CUSTOM_ACTION_BAR"

      snapshot_signals:
        # List of signals you want to take a snapshot of when the EAP is triggered
        - debug_signal_X
        - debug_signal_Y

      next_state_node: MY_SECOND_NODE   # Specify which state node the CLA should move to after this EAP is triggered. Must be a string matching the name of a deined node.

  MY_SECOND_NODE:
    ANOTHER_EAP:
      #....
```

### Program Fields

| Field      | Required? | Description | Legal Values |
| ----------- | ----------- | ----------- | ----------- |
| COUNTERS | optional  | A list of strings used for counter aliases. Allows you to use custom counter names rather than CLA_COUNTER_X | \<list(str)\>  |
| CUSTOM_ACTIONS | optional  | A set of custom action opcode aliases. Allows you to use these action names rather than explicity defining opcode values | \<dict\> |
| START_NODE | required  | Tells the compiler which node should be assigned to Node 0 (initial state) | \<str\> |
| NODES | required  | Each member of the NODES object is a CLA node. Each of these nodes can contain up to 4 event action pairs (EAPs) | \<dict\> |
| LFSR | optional (required when the LFSR event is used) | Configuration of the CLA LFSR: `seed` (non-zero initial value, up to 63 bits) and `mask` (feedback taps, up to 63 bits). The LFSR is enabled when this section is present | \<dict\> |

### EAP Fields

| Field      | Required? | Description | Legal Values |
| ----------- | ----------- | ----------- | ----------- |
| debug_mux_reg | optional  | Specify the name of the debug mux select register to use for this EAP (some units have multiple registers for the same mux instance) | \<str\> |
| event_triggers | required  | Each member of the event_triggers field is an event. Up to 4 events can be specified. The event names can be arbitrary | \<dict\> |
| event_triggers.X | required  | List of strings that specify the conditions required for event X | \<list(str)\> |
| event_logical_op | required  | Logical operation between the events needed to trigger the EAP. Must be a valid logical expression in either verilog or python syntax | \<str\> |
| actions | optional  | List of actions to take when the EAP is triggered. Up to 4 actions can be specified | \<list(str, int, hex)\>  |
| custom_actions | optional  | List of custom actions to take when the EAP is triggered. Up to 2 actions can be specified | \<list(str, int, hex)\>  |
| snapshot_signals | optional  | List of signals you want to output on the debug bus for a snapshot. Signals only need to be added here if they are not used in an event trigger | \<list(str)\>  |
| next_state_node | required  | Specify which state node the CLA should move to after this EAP is triggered. Must be a string matching the name of a deined node | \<str\> |

### Event Triggers

| Format      | Description | 
| ----------- | ----------- | 
| ALWAYS_ON | Will always trigger |
| *rtl_signal_name* == *value* | Will trigger when (*rtl_signal_name* == *value*). *rtl_signal_name* must be defined in the dbm info json. |
| *rtl_signal_name* != *value* | Will trigger when (*rtl_signal_name* != *value*). *rtl_signal_name* must be defined in the dbm info json. |
| *counter_alias* == *value* | Will trigger when (*counter_alias* == *value*). *counter_alias* must be defined in COUNTERS field. |
| *counter_alias* < *value* | Will trigger when (*counter_alias* < *value*). *counter_alias* must be defined in COUNTERS field. |
| *counter_alias* > *value* | Will trigger when (*counter_alias* > *value*). *counter_alias* must be defined in COUNTERS field. |
| posedge *rtl_signal_name* | Will trigger *rtl_signal_name* transitions from 0 to 1. *rtl_signal_name* must be defined in the dbm info json. |
| negedge *rtl_signal_name* | Will trigger *rtl_signal_name* transitions from 1 to 0. *rtl_signal_name* must be defined in the dbm info json. |
| XTRIGGER_0 | Will trigger when CLA recieves an external trigger[0] |
| XTRIGGER_1 | Will trigger when CLA recieves an external trigger[1] |
| transition(*rtl_signal_name*, *from_value*, *to_value*) | Will trigger when *rtl_signal_name* transitions from *from_value* to *to_value*. Useful for tracking state machine transitions. *rtl_signal_name* must be defined in the dbm info json. |
| anychange(*rtl_signal_name*) | Will trigger when *rtl_signal_name* changes value |
| countones(*rtl_signal_name*) == *value* | Will trigger when the total number of 1 bits in *rtl_signal_name* equals *value*. Useful for one-hot rules. *rtl_signal_name* must be defined in the dbm info json. |
| PERIOD_TICK | Will trigger when a periodic tick occurs |
| *rtl_signal_name* < *value* | Will trigger when (*rtl_signal_name* < *value*) (arithmetic compare, unsigned). *rtl_signal_name* must be defined in the dbm info json. Also supports `<=`, `>` and `>=`. At most 4 distinct (signal, value) pairs per program. Only one signal per event, and the signal bits must keep their order on the CLA debug bus |
| LFSR | Will trigger when the LFSR output bit is set. Requires the LFSR section in the program |

#### Signal Names
RTL signal names can be used directly in your program description if you have provided a debug bus config file.\
Without a config file, you can only use the signal name "debug_signals" in your CLA program description, which is the 64b input to the CLA module.\
Refer to [../../docGen/README.md](../../docGen/README.md) for details on how to generate a debug bus config file.

Signal names can be indexed in your program.
```yaml
#Valid
event_triggers:                   
  myEvent_A:
    - rtl_signal_name[3:0] == value
```

#### Multiple Triggers
Multiple different trigger types cannot be combined in a single event.
```yaml
#Invalid
event_triggers:                   
  myEvent_A:
    - rtl_signal_name == value
    - XTRIGGER_0
```

The above example is invalid, since an event cannot be triggered off both an rtl signal match and an external trigger.\
If we want to trigger the EAP when (rtl_signal_name == value) & (external_trigger[0]), we need to split them into two events:
```yaml
#Valid
event_triggers:                   
  myEvent_A:
    - rtl_signal_name == value
  myEvent_B:
    - XTRIGGER_0
event_logical_op: myEvent_A && myEvent_B
```

Furthermore, the only trigger types that can be combined into a single event are "rtl_signal_name == value", "anychange(rtl_signal_name)", and "transition(rtl_signal_name, from_value, to_value)". All other event triggers must be used stand alone.
```yaml
#Valid
event_triggers:                   
  multiMatchEvent:
    # Triggerred when (rtl_signal_A == value_A) & (rtl_signal_B == value_B) & (rtl_signal_C == value_C)
    - rtl_signal_A == value_A
    - rtl_signal_B == value_B
    - rtl_signal_C == value_C
```
```yaml
#Valid
event_triggers:                   
  anyChangeEvent:
    # Triggerred when (anychange(rtl_signal_A)) | (anychange(rtl_signal_B)) | (anychange(rtl_signal_C))
    - anychange(rtl_signal_A)
    - anychange(rtl_signal_B)
    - anychange(rtl_signal_C)
```
```yaml
#Valid
event_triggers:                   
  multiTransitionEvent:
    # Triggerred when (transition(rtl_signal_A, from_value_A, to_value_A)) & (transition(rtl_signal_B, from_value_B, to_value_B)) & (transition(rtl_signal_C, from_value_C, to_value_C))
    - transition(rtl_signal_A, from_value_A, to_value_A)
    - transition(rtl_signal_B, from_value_B, to_value_B)
    - transition(rtl_signal_C, from_value_C, to_value_C)
```

### Actions

| Format      | Description | 
| ----------- | ----------- | 
| NULL | Do nothing |
| CLOCK_HALT | Stop all clocks at cluster level |
| DEBUG_INTERRUPT | Assert a “debug interrupt” to core. Leverage DM implementation |
| TOGGLE_GPIO | Toggle GPIO (or other equivalent pins) for external visibility |
| START_TRACE |  |
| STOP_TRACE |  |
| TRACE_PULSE | Trace for single cycle (when trigger fires)  |
| CROSS_TRIGGER_0 | Trigger to other CLAs |
| XTRIGGER_0 | Trigger to other CLAs (equivalent to CROSS_TRIGGER_0) |
| CROSS_TRIGGER_1 | Trigger to other CLAs |
| XTRIGGER_1 | Trigger to other CLAs (equivalent to CROSS_TRIGGER_1) |
| INCREMENT *counter_alias* | Will increment *counter_alias*. *counter_alias* must be defined in COUNTERS field |
| CLEAR *counter_alias* | Will clear *counter_alias*. *counter_alias* must be defined in COUNTERS field |
| AUTO_INCREMENT *counter_alias* | Will start to auto increment *counter_alias* every cycle. *counter_alias* must be defined in COUNTERS field |
| STOP_AUTO_INCREMENT *counter_alias* | Will stop incrementing *counter_alias* every cycle. *counter_alias* must be defined in COUNTERS field |

### Changes in v2.0
* Targets CLA MMR v2.x (the v1 register layouts are no longer supported).
* Output is organised per CLA instance and contains absolute register addresses.
* Register names follow the MMR spec (`c_dbg_*`, with `_lo`/`_hi` for 128b values). The edge detect signal select fields are 7 bits wide, and the signal delay register has 16 lane fields.
* The debug bus is 128b by default (`--debugBusWidth 64` for 64b configurations). Muxes that feed another mux take their output width from the downstream mux input; only the final mux is as wide as the CLA debug bus.
* New events: arithmetic compare (`<`, `<=`, `>`, `>=` on debug signals) and LFSR.
* The compiler exits with code 1 on any error. Event names can be any string (they are matched as whole tokens in `event_logical_op`, so names like `a` or `order` do not clash with `and`/`or`).
