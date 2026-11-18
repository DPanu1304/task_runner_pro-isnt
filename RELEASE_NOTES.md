# JobRunner — Release Notes v1.0.0

**Fecha:** 16 de noviembre de 2026
**Versión:** 1.0.0
**Estado:** Producto final

---

## Resumen

JobRunner es un servicio ligero para Linux que ejecuta comandos
en segundo plano, con arquitectura cliente/servidor sobre TCP,
cola de trabajos con límite de concurrencia, persistencia atómica
y recuperación tras reinicios.

## Novedades desde v0.2.0

- Migración de socket Unix a TCP (operación remota).
- Whitelist de IPs (seguridad de red).
- Manejo de mensajes fragmentados.
- Tests de red (TC-010, TC-011, TC-012).

## Funcionalidad completa

| Requisito | Estado |
|---|---|
| Envío de trabajos | ✅ |
| Identificador único | ✅ |
| Ejecución como proceso separado | ✅ |
| Consulta de estado | ✅ |
| Listado con filtros | ✅ |
| Cancelación | ✅ |
| Cola con límite | ✅ |
| Captura separada stdout/stderr | ✅ |
| Persistencia atómica | ✅ |
| Recuperación tras reinicio | ✅ |
| Bitácora | ✅ |
| TCP + cliente remoto | ✅ |
| Whitelist de IPs | ✅ |
| Watchdog de timeout | ✅ |

## Instalación

    git clone https://github.com/DPanu1304/task_runner_pro-isnt.git
    cd task_runner_pro-isnt
    make -C src

## Ejecución

    ./src/server daemon
    ./src/server submit echo "hola"
    ./src/server status 1
    ./src/server shutdown

## Pruebas

    make -C src test

Resultado esperado: PASS=9 FAIL=0.
