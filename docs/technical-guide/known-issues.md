# Known Issues — JobRunner v1.0.0

Documento de defectos y limitaciones conocidas del producto.

---

## Limitaciones conocidas

### L-001: TIME_WAIT tras caída abrupta del servidor
- **Síntoma:** Después de un `kill -9` del daemon, el puerto TCP puede
  permanecer en `TIME_WAIT` durante ~60 segundos.
- **Impacto:** Un reinicio inmediato en el mismo puerto puede fallar con
  `Address already in use`.
- **Mitigación:** `SO_REUSEADDR` aplicado. En tests se usan puertos aleatorios.
- **Estado:** Aceptado como limitación del protocolo TCP.

### L-002: Persistencia JSON escala hasta ~500 trabajos
- **Síntoma:** Cada cambio de estado reescribe todo el archivo `jobs.json`.
- **Impacto:** Con miles de trabajos, el rendimiento de escritura degrada.
- **Mitigación:** Documentado en ADR-0003. Si se escalara, se migraría a SQLite.
- **Estado:** Aceptado para el alcance actual.

### L-003: Whitelist no soporta CIDR (/24)
- **Síntoma:** `allowed_ips` requiere IPs exactas; no acepta rangos como
  `192.168.1.0/24`.
- **Impacto:** Para permitir una subred hay que listar cada IP.
- **Mitigación:** Añadir manualmente cada IP a la lista.
- **Estado:** Mejora para una versión futura.

### L-004: Comandos con tabulaciones en argumentos
- **Síntoma:** El protocolo de petición usa `\t` como separador.
- **Impacto:** Un argumento con `\t` rompe el parseo.
- **Mitigación:** Escapar el tabulador en el cliente.
- **Estado:** Aceptado.

### L-005: El cliente no tiene autenticación de usuario
- **Síntoma:** Cualquier cliente en una IP autorizada puede enviar comandos.
- **Impacto:** La seguridad depende de la whitelist de IPs, no de credenciales.
- **Mitigación:** Restringir la whitelist a la VPN/LAN.
- **Estado:** Fuera del alcance del Hito Final.

---

## Defectos resueltos (post mortem)

### D-001: Cliente colgado esperando EOF (resuelto)
- **Versión afectada:** v0.1.0, v0.2.0
- **Síntoma:** `submit sleep 300` tardaba 5 minutos.
- **Causa:** El hijo de `fork()` heredaba el socket aceptado sin `FD_CLOEXEC`.
- **Solución:** Añadir `FD_CLOEXEC` en `accept()` y `listen()`.
- **Evidencia:** INC-002.
- **Estado:** ✅ Resuelto en v0.2.0.

### D-002: `max_queue_size` ignorado (resuelto)
- **Versión afectada:** v0.2.0 (en desarrollo)
- **Síntoma:** El daemon no rechazaba cuando la cola estaba llena.
- **Causa:** El setter `set_limits` asignaba al parámetro local, no al
  miembro `max_queue_size_`.
- **Solución:** Corregir la asignación en `job_registry.cpp`.
- **Evidencia:** TC-016.
- **Estado:** ✅ Resuelto en v0.2.0.

### D-003: Tests del Hito 2 incompatibles con TCP (resuelto)
- **Versión afectada:** v1.0.0 (en desarrollo)
- **Síntoma:** TC-002, TC-007, TC-016 y TC-021 fallaban tras migrar a TCP.
- **Causa:** Usaban `JOBRUNNER_SOCKET` que ya no aplica.
- **Solución:** Adaptar los tests a `JOBRUNNER_HOST`/`JOBRUNNER_PORT`
  y usar puertos aleatorios.
- **Evidencia:** Commit `fix(hito-3): adapta tests del Hito 2 a TCP`.
- **Estado:** ✅ Resuelto en v1.0.0.
