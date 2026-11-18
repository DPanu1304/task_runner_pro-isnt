# JobRunner — Guía técnica

## Compilación

    make -C src clean
    make -C src

Requisitos: g++ ≥ 9, Linux, sin privilegios de root. Compila sin
warnings con `-Wall -Wextra -Werror -std=c++17`.

## Ejecución de pruebas

    make -C src test

Ejecuta `verif/scripts/run_tests.sh`, que corre 9 casos (TC-001 a
TC-021) y deja evidencia en `verif/results/<run-id>/`.

## Configuración — `config.json`

{
  "max_workers": 3,
  "max_queue_size": 100,
  "max_timeout_sec": 300,
  "data_dir": "./data",
  "log_file": "jobrunner.log",
  "bind_ip": "127.0.0.1",
  "port": 8080,
  "allowed_ips": ["127.0.0.1", "192.168.1.0"]
}

- `bind_ip`: IP donde escucha el daemon (0.0.0.0 para todas las interfaces).
- `port`: puerto TCP.
- `allowed_ips`: IPs autorizadas. Si está vacía, permite todo (útil para tests).

## Arquitectura

    CLIENTE ── TCP ──► DAEMON ── fork/execvp ──► hijo
                           │
                           ├─ Cola FIFO (deque<int>)
                           ├─ Persistencia (data/jobs.json)
                           ├─ Bitácora (jobrunner.log)
                           └─ Whitelist de IPs (allowed_ips)

## Protocolo TCP

- Una línea por petición, delimitador `\n`.
- Verbo + argumentos separados por `\t`.
- Verbo de respuesta: `OK` o `ERR`.
- Tamaño máximo de línea: 64 KB.

## Persistencia atómica

1. Escribe en `data/jobs.json.tmp`.
2. `fsync(fd)`.
3. `rename(tmp, final)` (operación atómica POSIX).
4. `fsync(dir)`.

Al arrancar, los `RUNNING` huérfanos pasan a `FAILED` con
`note="interrupted by restart"`.

## Logs

Formato: `[YYYY-MM-DD HH:MM:SS.mmm] [LEVEL] [job=N] mensaje`.
Niveles: INFO, WARN, ERROR. Se abre en modo append.

## Cancelación

- `QUEUED`: pasa a `CANCELED` sin señal.
- `RUNNING`: SIGTERM, y tras 3 s SIGKILL (escalamiento).

## Watchdog (Timeout automático)

Si un trabajo excede `max_timeout_sec` (default 300s), el daemon lo
cancela automáticamente y lo marca como `FAILED` con nota
`timeout exceeded`. Desactivado con `max_timeout_sec: 0`.

## Variables de entorno

- `JOBRUNNER_HOST`: IP/host del daemon (default 127.0.0.1).
- `JOBRUNNER_PORT`: puerto del daemon (default 8080).
- `JOBRUNNER_SOCKET`: ruta del socket Unix (solo modo legacy).

## Ver Known Issues

Ver `docs/technical-guide/known-issues.md`.
