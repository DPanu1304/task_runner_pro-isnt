# JobRunner — Guía de usuario

## Inicio rápido

### Terminal 1 — Arrancar el servicio

    ./src/server daemon

Debe imprimir:

    [daemon] escuchando en 127.0.0.1:8080 (pid=XXXXX)

### Terminal 2 — Enviar comandos

    ./src/server submit echo hola
    # → OK id=1 pid=XXXX state=RUNNING

    ./src/server status 1
    # → OK
    #   id=1 state=SUCCEEDED cmd=echo pid=XXXX exit=0
    #   --stdout--
    #   hola

    ./src/server shutdown
    # → OK shutting down

## Comandos disponibles

| Comando | Qué hace |
|---|---|
| `server help` | Muestra la ayuda |
| `server daemon` | Arranca el servicio |
| `server submit <cmd> [args...]` | Envía un trabajo, devuelve ID |
| `server status <id>` | Estado + stdout/stderr |
| `server list [STATE]` | Lista o filtra por estado |
| `server cancel <id>` | Cancela (SIGTERM → SIGKILL) |
| `server health` | Estado global del daemon |
| `server shutdown` | Cierre ordenado |
| `server <cmd> [args...]` | Modo legacy síncrono |

## Estados

- **QUEUED** — En cola, esperando slot libre.
- **RUNNING** — En ejecución.
- **SUCCEEDED** — Terminó con exit code 0.
- **FAILED** — Exit code ≠ 0, señal o error interno.
- **CANCELED** — Cancelado por el cliente o por timeout.

## Operación remota

Para conectar desde otra máquina en la misma LAN:

    # En la máquina cliente
    export JOBRUNNER_HOST=<IP_DEL_SERVIDOR>
    export JOBRUNNER_PORT=8080

    ./src/server submit echo "remoto"

**Importante:** La IP del cliente debe estar en `allowed_ips` del
`config.json` del servidor.

## Ejemplo completo — cola con límite

    ./src/server submit sleep 30   # OK id=1 ... RUNNING
    ./src/server submit sleep 30   # OK id=2 ... RUNNING
    ./src/server submit sleep 30   # OK id=3 ... RUNNING
    ./src/server submit sleep 30   # OK id=4 state=QUEUED
    ./src/server health            # running=3 queued=1
    ./src/server cancel 4          # cancel requested (QUEUED)
    ./src/server list              # ver todos los jobs
    ./src/server shutdown          # cierre limpio

## Recuperación tras reinicio

Si el daemon se cae (kill -9), al volver a arrancarlo los trabajos
que estaban RUNNING aparecen como FAILED con
`note=interrupted by restart`. No hay estados imposibles.

## Cambio de configuración

Edita `config.json` antes de arrancar el daemon:

- `max_workers`: trabajos concurrentes.
- `max_queue_size`: capacidad de la cola.
- `max_timeout_sec`: timeout automático (Watchdog).
- `bind_ip` / `port`: dónde escucha el daemon.
- `allowed_ips`: IPs autorizadas.

Si el archivo no existe, se crea con valores por defecto.
