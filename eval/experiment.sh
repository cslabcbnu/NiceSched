#!/usr/bin/env bash
set -euo pipefail

#######################################
# Global Config
#######################################
BASE_DIR="/home/binwon"
BENCH_DIR="$BASE_DIR/benchmarks"
SCRIPT_DIR="$BASE_DIR/script"
LOG_ROOT="$BASE_DIR/nice-log"
NUMA_LOG="$BASE_DIR/numa-log"
MOUNT_POINT="/mnt/numa0-tmp"

declare -A WORKLOAD_CMDS=(
  [xs]="$BENCH_DIR/XSBench/openmp-threading/XSBench -t 22 -p {MEM}"
  [npb]="$BENCH_DIR/npb/npb-omp/bin/ua.D.x"
  [gapbs-pr]="$BENCH_DIR/gapbs/pr -f $BENCH_DIR/gapbs/twitter-small.el -n 180"
  [gapbs-bfs]="$BENCH_DIR/gapbs/bfs -f $BENCH_DIR/gapbs/twitter-small.el -n {MEM}"
  [liblinear]="$BENCH_DIR/liblinear/train -s 2 -m 22 $BENCH_DIR/datasets/kdda -q"
)

# limit node 0 memory
MEM_RATIOS=("48" "53.3" "55" "56.6")
REPEAT=7

#######################################
# Logging Helpers
#######################################
log() { echo "[$(date '+%F %T')] $*"; }

#######################################
# Cleanup on exit / interrupt
#######################################
cleanup() {
    log "Cleaning up..."
    sudo umount "$MOUNT_POINT" 2>/dev/null || true
    sudo swapoff -a || true
}
trap cleanup EXIT SIGINT SIGTERM

#######################################
# Environment setup
#######################################
env_setup() {
    log "Disabling swap and containers"
    sudo swapoff -a
    sudo systemctl stop docker containerd libvirtd || true
}

#######################################
# Memory limitation via tmpfs
#######################################
mem_limit() {
    local mem="$1"
    local rounded
    rounded=$(printf "%.0f" "$mem")
    rounded=$((rounded + 1))

    log "Setting tmpfs to ${rounded}G (effective ${mem}G)"

    sudo umount "$MOUNT_POINT" 2>/dev/null || true
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount -t tmpfs -o size=${rounded}G,mpol=bind:0 tmpfs "$MOUNT_POINT"
    sudo fallocate -l ${mem}G "$MOUNT_POINT/dummy"
}

#######################################
# Run workload
#######################################
run_workload() {
    local name="$1"
    local mem="$2"
    local cmd_template="${WORKLOAD_CMDS[$name]}"
    local cmd="${cmd_template/\{MEM\}/$mem}"

    local log_dir="$LOG_ROOT/$name"
    mkdir -p "$log_dir"

    log "Running workload: $name (mem=$mem)"
    SECONDS=0
    eval "$cmd"
    wait
    echo "$SECONDS" >> "$log_dir/$(uname -r)-$mem.log"
}

#######################################
# Drop caches
#######################################
reset_state() {
    sudo sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
}

#######################################
# Main
#######################################
usage() {
  echo "Usage: $0 -w <workload>"
  exit 1
}

while getopts "w:" opt; do
  case $opt in
    w) WORKLOAD="$OPTARG" ;;
    *) usage ;;
  esac
done

[[ -z "${WORKLOAD:-}" ]] && usage
[[ -z "${WORKLOAD_CMDS[$WORKLOAD]:-}" ]] && { echo "Unsupported workload: $WORKLOAD"; exit 1; }

env_setup

for mem in "${MEM_RATIOS[@]}"; do
  mem_limit "$mem"
  for ((i=1;i<=REPEAT;i++)); do
      log "Iteration $i/$REPEAT for $WORKLOAD (mem=$mem)"
      reset_state
      run_workload "$WORKLOAD" "$mem"
  done
done

log "All experiments completed."

