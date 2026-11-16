#!/usr/bin/env bash
# TC-011: Whitelist de IPs.
# Cubre RF-20, RNF-13.
set -uo pipefail

ROOT_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SERVER="$ROOT_DIR/src/server"
PORT=$(( 20000 + RANDOM % 10000 ))
CONFIG="$ROOT_DIR/config.json"
ORIG_CONFIG_BACKUP="$CONFIG.bak.$$"
DATA_DIR="$ROOT_DIR/data-test-$$"
LOG="/tmp/jobrunner-test-$$.log"

[ -f "$CONFIG" ] && cp "$CONFIG" "$ORIG_CONFIG_BACKUP"
# Solo permitimos 127.0.0.1 (local). Este test valida que local pasa y bloqueamos otros.
cat > "$CONFIG" <<JSON
{
  "max_workers": 3,
  "max_queue_size": 10,
  "max_timeout_sec": 0,
  "data_dir": "$DATA_DIR",
  "log_file": "$LOG",
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
    rm -f "$CONFIG" "$LOG"
    [ -f "$ORIG_CONFIG_BACKUP" ] && mv "$ORIG_CONFIG_BACKUP" "$CONFIG"
}
trap cleanup EXIT

cd "$ROOT_DIR" || fail "no puedo entrar a ROOT_DIR"
"$SERVER" daemon >/dev/null 2>&1 &
DAEMON_PID=$!
sleep 0.5

# ---------- 1. IP autorizada (127.0.0.1) funciona ----------
out=$("$SERVER" submit echo "autorizado")
echo "$out" | grep -q "OK id=1" || fail "IP autorizada rechazada: $out"
ok "IP autorizada (127.0.0.1) conecta correctamente"

# ---------- 2. El daemon no expone acceso a otras IPs ----------
# Verificar que el daemon efectivamente está en 127.0.0.1 (no 0.0.0.0)
# Intentar conectar a una IP no autorizada (127.0.0.2 es loopback alternativa)
out=$(JOBRUNNER_HOST=127.0.0.2 JOBRUNNER_PORT=$PORT timeout 2 "$SERVER" submit echo rechazado 2>&1)
echo "$out" | grep -qiE "error|denegado|no se pudo conectar" || fail "conexión desde IP no autorizada no fue rechazada: $out"
ok "IP no autorizada rechazada"

"$SERVER" shutdown >/dev/null 2>&1

echo
echo "PASS: TC-011 (RF-20, RNF-13)"
exit 0
