# SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
# SPDX-License-Identifier: Apache-2.0
import yaml
import argparse

def parse_yaml_and_write(input_yaml, output_txt, cla_instance=None):
    # The input is the output of compileClaProgram.py. It contains the address and value of every register of
    # every CLA instance: claN -> registers -> <mmr_name> -> {address, value, fields}
    with open(input_yaml, "r") as yaml_file:
        data = yaml.safe_load(yaml_file)

    with open(output_txt, "w") as txt_file:
        for instance_name, instance in data.items():
            if cla_instance is not None and instance_name != "cla{}".format(cla_instance):
                continue

            for reg_name, reg in instance["registers"].items():
                # YAML loads unquoted hex literals as ints
                reg_address = reg["address"]
                if isinstance(reg_address, str):
                    reg_address = int(reg_address, 0)

                # Ensure the value is an integer
                val = reg["value"]
                if isinstance(val, str):
                    val = int(val, 0)  # Convert hex string or decimal string to int

                lower_32 = val & 0xFFFFFFFF
                upper_32 = (val >> 32) & 0xFFFFFFFF

                # A 64-bit register is accessed as two 4-byte aligned 32-bit words. Write the high word (address + 4)
                # first and the low word (address) last: some low-word fields (e.g. Valid in c_dbg_mux_sel_lo) act
                # as soon as the low word is written, so the rest of the register must already be in place.
                txt_file.write(f"write {hex(reg_address + 4)} {hex(upper_32)} f\n")
                txt_file.write(f"write {hex(reg_address)} {hex(lower_32)} f\n")

def main():
    parser = argparse.ArgumentParser(description="Parse a YAML file and write to a text file.")
    parser.add_argument("input_yaml", help="Path to the input YAML file.")
    parser.add_argument("-o", "--output", default="cla_apb_traffic.txt", help="Path to the output text file (default: cla_apb_traffic.txt).")
    parser.add_argument("--cla", type=int, default=None, help="Only generate traffic for this CLA instance (default: all instances in the YAML file).")

    args = parser.parse_args()
    parse_yaml_and_write(args.input_yaml, args.output, args.cla)

if __name__ == "__main__":
    main()
