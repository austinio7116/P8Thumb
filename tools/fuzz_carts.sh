#!/usr/bin/env bash
# Fuzz harness: run every cart in carts/ for N frames and capture errors.
#
# Usage: tools/fuzz_carts.sh [frames]   (default 300 = 10s at 30fps)
#
# Outputs:
#   /tmp/fuzz_<cart_name>.log   per-cart stderr
#   /tmp/fuzz_summary.txt       triage report (unique errors per cart)

set -u
FRAMES="${1:-300}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
P8RUN="$HERE/build_host/p8run"
CARTS="$HERE/carts"
OUT_DIR="/tmp/p8fuzz"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*.log

if [[ ! -x "$P8RUN" ]]; then
    echo "missing host binary: $P8RUN" >&2
    exit 1
fi

# Use SDL dummy driver so we can run headless
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

# Fuzz button input each frame to exercise game logic beyond title screens
export P8_FUZZ_INPUT=1

n_carts=0
n_clean=0
n_error=0
n_hang=0

for cart in "$CARTS"/*.p8.png "$CARTS"/*.p8; do
    [[ -e "$cart" ]] || continue
    name=$(basename "$cart" .p8.png)
    name=$(basename "$name" .p8)
    log="$OUT_DIR/fuzz_${name}.log"
    n_carts=$((n_carts+1))

    # 30 fps × FRAMES + ~3s safety margin
    timeout_s=$(( (FRAMES / 30) + 5 ))
    timeout "${timeout_s}" "$P8RUN" "$cart" \
        --screenshot "$FRAMES" "$OUT_DIR/${name}.ppm" \
        > "$log.out" 2> "$log" 2>&1
    rc=$?

    if [[ $rc -eq 124 ]]; then
        echo "HANG  $name"
        n_hang=$((n_hang+1))
    elif [[ -s "$log" ]] && grep -q 'error:\|PANIC' "$log"; then
        echo "ERROR $name"
        n_error=$((n_error+1))
    else
        echo "OK    $name"
        n_clean=$((n_clean+1))
        rm -f "$log" "$log.out"
    fi
done

echo
echo "=== Summary ==="
echo "Total carts:  $n_carts"
echo "Clean (no errors): $n_clean"
echo "With errors:  $n_error"
echo "Hangs:        $n_hang"

# Build triage report
SUMMARY="$OUT_DIR/fuzz_summary.txt"
{
    echo "ThumbyP8 fuzz harness summary"
    echo "Frames per cart: $FRAMES"
    echo "Date: $(date)"
    echo ""
    echo "=== Errors by cart ==="
    for log in "$OUT_DIR"/fuzz_*.log; do
        [[ -f "$log" ]] || continue
        cname=$(basename "$log" .log | sed 's|^fuzz_||')
        echo ""
        echo "--- $cname ---"
        grep -E 'error:|PANIC' "$log" | sort -u
    done
    echo ""
    echo "=== Unique error patterns ==="
    grep -hE 'error:|PANIC' "$OUT_DIR"/fuzz_*.log 2>/dev/null \
        | sed -E "s|cart:[0-9]+:|cart:LINE:|" \
        | sed -E "s|'[A-Z_]+'|'IDENT'|g" \
        | sort | uniq -c | sort -rn
} > "$SUMMARY"

echo ""
echo "Triage report: $SUMMARY"
