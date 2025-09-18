#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CUST_DFD_DIR="${SCRIPT_DIR}/../../rtl/gen_files"

# Define features
features=("CLA" "DST" "NTRACE" "MMR")

# Function to generate output filename
gen_filename() {
    local name="dfd_top"
    for feat in "$@"; do
        name+="_${feat,,}"  # Convert to lowercase
    done
    echo "$CUST_DFD_DIR/${name}.sv"
}

# Function to update module name in file
update_module_name() {
    local file=$1
    local newname=$(basename "$2")  # Extract filename without path
    # Remove .sv extension for module name
    newname=${newname%.sv}
    # Use sed to replace the module name
    sed -i "s/module dfd_top/module ${newname}/" "$file"
}

# Generate all possible combinations
n=${#features[@]}
for ((i=1; i<2**n; i++)); do  # Start from 1 to skip empty set
    args=()
    name_parts=()
    
    for ((j=0; j<n; j++)); do
        if (( (i & (1<<j)) != 0 )); then
            args+=("--${features[j]}")
            name_parts+=("${features[j]}")
        fi
    done
    
    outfile=$(gen_filename "${name_parts[@]}")
    echo "Generating $outfile..."
    # First run the sv_processor
    python3 "$SCRIPT_DIR/process_sv.py" "$CUST_DFD_DIR/../dfd/dfd_top.sv" "$outfile" "${args[@]}"
    # Then update the module name
    update_module_name "$outfile" "$outfile"
done