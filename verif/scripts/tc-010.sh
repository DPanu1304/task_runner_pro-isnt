#!/usr/bin/env bash
# TC-010: Flujo remoto completo sobre TCP.
# Cubre RF-18, RF-19, RNF-12.
set -uo pipefail

ROOT_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SERVER="$ROOT_DIR/src/server"
PORT=$(( 20000 + RANDOM % 10000 ))
CONFIG="$ROOT_DIR/config.json"
ORIG_CONFIG_BACKUP="$CONFIG.bak.$$"
DATA_DIR="$ROOT_DIR/data-test-$$"

[ -f "$CONFIG" ] && cp "$CONFIG" "$ORIG_CONFIG_BACKUP"
cat > "$CONFIG" <<JSON
{
  "max_workers": 3,
  "max_queue_size": 10,
  "max_timeout_sec": 0,
  "data_dir": "$DATA_DIR",
  "log_file": "/tmp/jobrunner-test-$$.log",
  "bind_ip": "127.0.0.1",
  "port": $PORT,
  "allowed_ips": ["127.0.0.1"]
}
JSON

export JOBRUNNER_HOST="127.0.0.1"
export JOBRUNNER_PORT="$PORT"

fail() { echo "FAIL: $*"; exit 1; }
ok()   { echo "OK: $*"; }

cleanup() {
    "$SERVER" shutdown >/dev/null 2>&1 || true
    pkill -9 -x server 2>/dev/null || true
    rm -rf "$DATA_DIR"
    rm -f "$CONFIG"
    [ -f "$ORIG_CONFIG_BACKUP" ] && mv "$ORIG_CONFIG_BACKUP" "$CONFIG"
}
trap cleanup EXIT

cd "$ROOT_DIR" || fail "no puedo entrar a ROOT_DIR"
"$SERVER" daemon >/dev/null 2>&1 &
DAEMON_PID=$!
sleep 0.5

# ---------- 1. Submit remoto ----------
out=$("$SERVER" submit echo "hola remoto")
echo "$out" | grep -q "OK id=1" || fail "submit remoto falló: $out"
ok "submit remoto funciona"

# ---------- 2. Status remoto ----------
sleep 0.5
out=$("$SERVER" status 1)
echo "$out" | grep -q "state=SUCCEEDED" || fail "status remoto no reporta SUCCEEDED: $out"
echo "$out" | grep -q "hola remoto" || fail "stdout no contiene 'hola remoto': $out"
ok "status remoto devuelve stdout"

# ---------- 3. List remoto ----------
out=$("$SERVER" list)
echo "$out" | grep -q "count=1" || fail "list remoto no reporta 1 job: $out"
ok "list remoto funciona"

# ---------- 4. Cancel remoto ----------
"$SERVER" submit sleep 600 >/dev/null
sleep 0.3
out=$("$SERVER" cancel 2)
echo "$out" | grep -q "cancel requested" || fail "cancel remoto falló: $out"
sleep 1
out=$("$SERVER" status 2)
echo "$out" | grep -qE "state=(CANCELED|FAILED)" || fail "job cancelado no quedó terminal: $out"
ok "cancel remoto funciona"

# ---------- 5. Shutdown remoto ----------
out=$("$SERVER" shutdown)
echo "$out" | grep -q "OK shutting down" || fail "shutdown remoto falló: $out"
ok "shutdown remoto funciona"

echo
echo "PASS: TC-010 (RF-18, RF-19, RNF-12)"
exit 0
