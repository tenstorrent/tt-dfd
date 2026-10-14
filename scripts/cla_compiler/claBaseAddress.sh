#!/bin/bash
# Calculates the CLA MMR base address (and the neighbouring block addresses) of the DFD MMR map.
#
# MMR order: DST Sink, NTR Sink, Funnel, CLA, DST, NTR. Each of the sinks/funnel occupies one 0x1000 window
# when present, and each CLA/DST/NTrace instance occupies one 0x1000 window. Instances of a block are contiguous.
#
# The result is meant to be passed to compileClaProgram.py:
#   compileClaProgram.py prog.yaml --claBaseAddress $(claBaseAddress.sh -q ...) --numCla N

WINDOW=0x1000

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -b <addr>  MMR base address (default 0x0)
  -d <0|1>   DST Sink present   (default 1)
  -n <0|1>   NTR Sink present   (default 1)
  -f <0|1>   Funnel present     (default 1)
  -c <num>   Number of CLA instances     (default 1)
  -s <num>   Number of DST instances     (default 1)
  -t <num>   Number of NTrace instances  (default 1)
  -q         Quiet: only print the CLA base address
  -h         Show this help

Example: $(basename "$0") -b 0x10000 -n 0 -c 4
EOF
}

die() { echo "ERROR: $*" >&2; exit 1; }

mmr_base=0
dst_sink=1
ntr_sink=1
funnel=1
num_cla=1
num_dst=1
num_ntrace=1
quiet=0

while getopts "b:d:n:f:c:s:t:qh" opt; do
  case "$opt" in
    b) mmr_base=$OPTARG ;;
    d) dst_sink=$OPTARG ;;
    n) ntr_sink=$OPTARG ;;
    f) funnel=$OPTARG ;;
    c) num_cla=$OPTARG ;;
    s) num_dst=$OPTARG ;;
    t) num_ntrace=$OPTARG ;;
    q) quiet=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

is_uint() { [[ $1 =~ ^(0[xX][0-9a-fA-F]+|[0-9]+)$ ]]; }

for var in mmr_base dst_sink ntr_sink funnel num_cla num_dst num_ntrace; do
  is_uint "${!var}" || die "$var must be a non-negative integer (decimal or 0x hex), got \"${!var}\""
done
for var in dst_sink ntr_sink funnel; do
  (( ${!var} <= 1 )) || die "$var must be 0 or 1, got \"${!var}\""
done
(( num_cla >= 1 )) || die "Number of CLA instances must be at least 1"
(( mmr_base % WINDOW == 0 )) || echo "WARNING: MMR base $(printf '0x%x' $((mmr_base))) is not aligned to $WINDOW" >&2

cla_start=$(( mmr_base + WINDOW * (dst_sink + ntr_sink + funnel) ))
cla_end=$((   cla_start + WINDOW * num_cla - 1 ))
dst_start=$(( cla_end + 1 ))
dst_end=$((   dst_start + WINDOW * num_dst - 1 ))
ntr_start=$(( dst_end + 1 ))
ntr_end=$((   ntr_start + WINDOW * num_ntrace - 1 ))

if (( quiet )); then
  printf '0x%x\n' "$cla_start"
  exit 0
fi

printf 'CLA_BASE_ADDRESS=0x%x\n' "$cla_start"
printf 'CLA_END_ADDRESS=0x%x\n'  "$cla_end"
for (( i = 0; i < num_cla; i++ )); do
  printf 'CLA_INST%d_BASE_ADDRESS=0x%x\n' "$i" $(( cla_start + i * WINDOW ))
done
printf 'DST_START_ADDRESS=0x%x\n' "$dst_start"
printf 'DST_END_ADDRESS=0x%x\n'   "$dst_end"
printf 'NTR_START_ADDRESS=0x%x\n' "$ntr_start"
printf 'NTR_END_ADDRESS=0x%x\n'   "$ntr_end"
