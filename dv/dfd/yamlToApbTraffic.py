import yaml
import argparse

# Define register map inside the script
REGISTER_MAP = {
    "CrCsrCdbgmuxsel__ID_0": "0x0198",
    "CrCsrCdbgmuxsel__ID_1": "0x0198",
    "CrCsrCdbgmuxsel__ID_2": "0x0198",
    "dbg_any_change": "0x31D8",
    "dbg_cla_counter0_cfg": "0x3100",
    "dbg_cla_counter1_cfg": "0x3108",
    "dbg_cla_counter2_cfg": "0x3110",
    "dbg_cla_counter3_cfg": "0x3118",
    "dbg_node0_eap0": "0x3120",
    "dbg_node0_eap1": "0x3128",
    "dbg_node0_eap2": "0x3148",
    "dbg_node0_eap3": "0x3150",
    "dbg_node1_eap0": "0x3130",
    "dbg_node1_eap1": "0x3138",
    "dbg_node1_eap2": "0x3158",
    "dbg_node1_eap3": "0x3160",
    "dbg_node2_eap0": "0x3140",
    "dbg_node2_eap1": "0x3148",
    "dbg_node2_eap2": "0x3168",
    "dbg_node2_eap3": "0x3170",
    "dbg_node3_eap0": "0x3150",
    "dbg_node3_eap1": "0x3158",
    "dbg_node3_eap2": "0x3178",
    "dbg_node3_eap3": "0x3180",
    "dbg_ones_count_mask": "0x31C8", 
    "dbg_ones_count_value": "0x31D0",
    "dbg_signal_edge_detect_cfg": "0x3180",
    "dbg_signal_mask0": "0x3160",
    "dbg_signal_mask1": "0x3170",
    "dbg_signal_mask2": "0x3228",
    "dbg_signal_mask3": "0x3238",
    "dbg_signal_match0": "0x3168",
    "dbg_signal_match1": "0x3178",
    "dbg_signal_match2": "0x3230",
    "dbg_signal_match3": "0x3240",
    "dbg_transition_from_value": "0x31B8",
    "dbg_transition_mask": "0x31B0",
    "dbg_transition_to_value": "0x31C0" 
    # Add more register mappings as needed
}

def parse_yaml_and_write(input_yaml, output_txt):
    with open(input_yaml, "r") as yaml_file:
        data = yaml.safe_load(yaml_file)
    
    with open(output_txt, "w") as txt_file:
        for key, value in data.items():
            if "value" in value:
                reg_address = int(REGISTER_MAP.get(key, key), 16)  # Convert address to integer
                
                # Ensure the value is an integer
                val = value['value']
                if isinstance(val, str):
                    val = int(val, 0)  # Convert hex string or decimal string to int
                
                lower_32 = val & 0xFFFFFFFF
                upper_32 = (val >> 32) & 0xFFFFFFFF
                
                txt_file.write(f"write {hex(reg_address)} {hex(lower_32)} f\n")
                txt_file.write(f"write {hex(reg_address + 4)} {hex(upper_32)} f\n")
def main():
    parser = argparse.ArgumentParser(description="Parse a YAML file and write to a text file.")
    parser.add_argument("input_yaml", help="Path to the input YAML file.")
    parser.add_argument("-o", "--output", default="cla_apb_traffic.txt", help="Path to the output text file (default: cla_apb_traffic.txt).")
    
    args = parser.parse_args()
    parse_yaml_and_write(args.input_yaml, args.output)

if __name__ == "__main__":
    main()
