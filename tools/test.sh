#!/usr/bin/env bash
# Import first: Godot needs its generated global-class and texture caches.
# Fail on engine errors too: GDScript can abort a function yet return exit zero.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT
run_checked() {
  if ! timeout 60s "$GODOT_BIN" "$@" > "$log_file" 2>&1; then
    cat "$log_file"
    return 1
  fi
  cat "$log_file"
  if grep -Eq 'SCRIPT ERROR:|(^|[[:space:]])ERROR:' "$log_file"; then
    return 1
  fi
}
run_checked --headless --path . --editor --import --quit
for test_file in tests/test_*.gd; do
  run_checked --headless --fixed-fps 60 --path . --script "res://$test_file"
  if ! grep -q 'PASS:' "$log_file"; then
    echo "Missing test completion marker: $test_file" >&2
    exit 1
  fi
done
