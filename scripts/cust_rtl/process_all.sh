#!/bin/bash
# SPDX-FileCopyrightText: Copyright 2026 Tenstorrent AI ULC
# SPDX-License-Identifier: Apache-2.0

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CUST_DFD_DIR="${SCRIPT_DIR}/../../rtl/gen_files"

# Explicit list of supported variants. Every generated variant is MMR (INTERNAL_MMRS).
# Each entry is "output_basename|FEATURE_FLAGS".
#
# Variant families (all MMR):
#   - internal trace : DST/NTRACE encoders + trace network (dfd_trace_top) in one block
#   - notrace        : DST/NTRACE encoders only; trace network is external. Exposes the
#                      dfd_unit-side TNIF ports (tnif_*_o data out, tnif_*_i flow-ctrl in).
#   - tnif           : trace network only, no DST/NTRACE encoders. Exposes the network-side
#                      TNIF ports (tnif_*_i data in, tnif_*_o flow-ctrl out). Mirrors notrace.
#
# A notrace block connects directly to a tnif block via their complementary TNIF ports.
variants=(
    # Internal trace (encoders + network)
    "dfd_top_dst_mmr|DST MMR"
    "dfd_top_ntrace_mmr|NTRACE MMR"
    "dfd_top_dst_ntrace_mmr|DST NTRACE MMR"
    "dfd_top_cla_dst_mmr|CLA DST MMR"
    "dfd_top_cla_ntrace_mmr|CLA NTRACE MMR"
    "dfd_top_cla_dst_ntrace_mmr|CLA DST NTRACE MMR"
    # NOTRACE (encoders only; trace network external)
    "dfd_top_dst_notrace_mmr|DST NOTRACE MMR"
    "dfd_top_ntrace_notrace_mmr|NTRACE NOTRACE MMR"
    "dfd_top_dst_ntrace_notrace_mmr|DST NTRACE NOTRACE MMR"
    "dfd_top_cla_dst_notrace_mmr|CLA DST NOTRACE MMR"
    "dfd_top_cla_ntrace_notrace_mmr|CLA NTRACE NOTRACE MMR"
    "dfd_top_cla_dst_ntrace_notrace_mmr|CLA DST NTRACE NOTRACE MMR"
    # TNIF (trace network only; encoders external). The TNIF port exposure is derived in
    # the template from TRACE_SUPPORT & !(DST || NTRACE), i.e. MMR-only / CLA+MMR-only here.
    "dfd_top_tnif|MMR"
    "dfd_top_cla_tnif|CLA MMR"
)

# Function to update module name in file
update_module_name() {
    local file=$1
    local newname=$(basename "$2")  # Extract filename without path
    # Remove .sv extension for module name
    newname=${newname%.sv}
    # Use sed to replace the module name
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/module dfd_top/module ${newname}/" "$file"
    else
        sed -i "s/module dfd_top/module ${newname}/" "$file"
    fi
}

for entry in "${variants[@]}"; do
    name="${entry%%|*}"
    feats="${entry#*|}"
    outfile="${CUST_DFD_DIR}/${name}.sv"

    args=()
    for feat in $feats; do
        args+=("--${feat}")
    done

    echo "Generating $outfile..."
    # First run the sv_processor
    python3 "$SCRIPT_DIR/process_sv.py" "$CUST_DFD_DIR/../dfd/dfd_top.sv" "$outfile" "${args[@]}"
    # Then update the module name
    update_module_name "$outfile" "$outfile"
done
