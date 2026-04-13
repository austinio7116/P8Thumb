#!/usr/bin/env bash
# Fuzz harness: run every cart in carts/ for N frames with random
# input fuzzing, take periodic screenshots, build a contact sheet
# per cart for visual review.
#
# Usage: tools/fuzz_carts.sh [seconds]   (default 60s @ 30fps = 1800 frames)
#
# Outputs:
#   /tmp/p8fuzz/<cart>_NNNN.ppm   per-cart screenshots (every 10s)
#   /tmp/p8fuzz/<cart>_sheet.png  contact sheet (all shots side by side)
#   /tmp/p8fuzz/all_sheet.png     grand contact sheet (one row per cart)
#   /tmp/p8fuzz/fuzz_summary.txt  triage report

set -u
SECONDS_PER_CART="${1:-60}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
P8RUN="$HERE/build_host/p8run"
CARTS="$HERE/carts"
OUT_DIR="/tmp/p8fuzz"

FPS=30
FRAMES=$((SECONDS_PER_CART * FPS))
SHOT_INTERVAL=$((10 * FPS))   # screenshot every 10 seconds

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*.ppm "$OUT_DIR"/*.png "$OUT_DIR"/*.log "$OUT_DIR"/*.out

if [[ ! -x "$P8RUN" ]]; then
    echo "missing host binary: $P8RUN" >&2
    exit 1
fi

export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export P8_FUZZ_INPUT=1
export P8_SCREENSHOT_INTERVAL="$SHOT_INTERVAL"

n_carts=0; n_clean=0; n_error=0; n_hang=0

for cart in "$CARTS"/*.p8.png "$CARTS"/*.p8; do
    [[ -e "$cart" ]] || continue
    name=$(basename "$cart" .p8.png)
    name=$(basename "$name" .p8)
    log="$OUT_DIR/${name}.log"
    n_carts=$((n_carts+1))

    timeout_s=$(( SECONDS_PER_CART + 5 ))
    P8_SCREENSHOT_PREFIX="$OUT_DIR/${name}" \
        timeout "${timeout_s}" "$P8RUN" "$cart" \
        --screenshot "$FRAMES" "$OUT_DIR/${name}_final.ppm" \
        > "$log.out" 2> "$log"
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

    # Build per-cart contact sheet (horizontal montage of screenshots)
    shots=( "$OUT_DIR/${name}"_*.ppm )
    if [[ -e "${shots[0]}" ]]; then
        montage "${shots[@]}" -tile "${#shots[@]}x1" -geometry +2+0 \
            -background black "$OUT_DIR/${name}_sheet.png" 2>/dev/null
    fi
done

# Grand contact sheet — all carts, one row each
all_sheets=( "$OUT_DIR"/*_sheet.png )
if [[ -e "${all_sheets[0]}" ]]; then
    # Annotate each row with the cart name
    rm -f "$OUT_DIR"/_labelled_*.png
    for sheet in "${all_sheets[@]}"; do
        sname=$(basename "$sheet" _sheet.png)
        convert "$sheet" -gravity West -background black -splice 90x0 \
            -fill white -pointsize 14 -annotate +5+0 "$sname" \
            "$OUT_DIR/_labelled_${sname}.png" 2>/dev/null
    done
    montage "$OUT_DIR"/_labelled_*.png -tile 1x -geometry +0+2 \
        -background gray20 "$OUT_DIR/all_sheet.png" 2>/dev/null
fi

echo
echo "=== Summary ==="
echo "Total: $n_carts | Clean: $n_clean | Errors: $n_error | Hangs: $n_hang"
echo "Per-cart sheets: $OUT_DIR/<cart>_sheet.png"
echo "Grand sheet:     $OUT_DIR/all_sheet.png"

# Triage report
SUMMARY="$OUT_DIR/fuzz_summary.txt"
{
    echo "ThumbyP8 fuzz harness — $(date)"
    echo "Frames: $FRAMES | Shot every: $SHOT_INTERVAL frames | Input: fuzzed"
    echo ""
    echo "=== Errors by cart ==="
    for log in "$OUT_DIR"/*.log; do
        [[ -f "$log" ]] || continue
        cname=$(basename "$log" .log)
        echo ""
        echo "--- $cname ---"
        grep -E 'error:|PANIC' "$log" | sort -u
    done
} > "$SUMMARY"
echo "Triage report: $SUMMARY"
