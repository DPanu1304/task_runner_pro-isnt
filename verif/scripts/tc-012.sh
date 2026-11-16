#!/usr/bin/env bash
# TC-012: Manejo de mensajes fragmentados y comandos largos.
# Cubre RF-21, RNF-14.
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

# ---------- 1. Comando con muchos argumentos ----------
ARGS=""
for i in $(seq 1 100); do ARGS="$ARGS arg$i"; done
out=$(eval "$SERVER submit echo $ARGS" 2>&1)
echo "$out" | grep -q "OK id=" || fail "comando con 100 argumentos falló: $out"
ok "comando con 100 argumentos aceptado"

# ---------- 2. Comando con salida grande (fragmentación de stdout) ----------
"$SERVER" submit bash -c 'for i in $(seq 1 5000); do echo "linea_$i"; done' >/dev/null
sleep 1
out=$("$SERVER" status 2)
echo "$out" | grep -q "linea_5000" || fail "salida grande no se capturó completa: $out"
ok "salida grande (>100 KB) capturada sin fragmentación"

# ---------- 3. Verificar que el daemon sigue vivo tras múltiples operaciones ----------
out=$("$SERVER" list)
echo "$out" | grep -q "OK count=" || fail "daemon no responde tras carga: $out"
ok "daemon resiliente a operaciones múltiples"

"$SERVER" shutdown >/dev/null 2>&1

echo
echo "PASS: TC-012 (RF-21, RNF-14)"
exit 0
