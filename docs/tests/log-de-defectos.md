# Log de Defectos — Plan de Pruebas

> Fuente única de verdad. Cada defecto vive aquí; las sesiones de QA referencian por ID.
> Este archivo se referencia desde `Plan de Pruebas de Software v2.0.docx` (§7.4) y
> se irá extendiendo con cada módulo (M2/M3) en versiones sucesivas (v3.0 — NT-021).

## Convenciones

- **ID**: `BUG-<modulo>-<NNN>` (ej. `BUG-M1-001`).
- **Severidad**: Crítica / Alta / Media / Baja (matriz §7.1 del Plan de Pruebas).
- **Estatus**: Abierto / En revisión / Resuelto / Cerrado / Reabierto.
- **Sesión origen**: ruta relativa a `CLAUDE_SESSIONS/reportes/` que detectó el defecto.

## Resumen por severidad (corte 2026-05-27, Módulo 1)

| Severidad | Cantidad |
|---|---:|
| Crítica | 0 |
| Alta | 0 |
| Media | 2 |
| Baja | 1 |
| **Total** | **3** |

## Tabla

| ID | Módulo | Severidad | Título | Caso / Endpoint | Estatus | Sesión origen | Notas |
|----|--------|-----------|--------|-----------------|---------|---------------|-------|
| BUG-M1-001 | M1 | Media | Endpoint `GET /comprobantes/:id/validacion-sat` no existe como ruta independiente | NT-006 — Postman M1 Fiscal, request "GET validacion-sat" | Cerrado (no-fix) | `2026-04-20_nt-006-postman-m1-fiscal.md` | La validación SAT está integrada dentro de `POST /api/comprobantes/:receipt_id` (PR #31, `feat/full/sat-cfdi-consulta`). Se documentó como decisión de producto; la colección Postman valida `sat_estado` en la respuesta del POST. 5/6 endpoints originales del spec NT-006 están cubiertos. |
| BUG-M1-002 | M1 | Media | Pre-request de colección Postman M2 usa credenciales seed obsoletas (era MariaDB) | NT-016 re-ejecución 2026-05-27, 4 logins en pre-request fallan con 401 | Abierto | `2026-05-27_nt-016-postman-m2-verification.md` | Drift de fixture: la colección hardcodea `admin/admin123`, `andres.gomez/andres123`, `laura.flores/laura321`, `diego.hernandez/diego654`. Estos usuarios desaparecieron cuando el stack migró a Postgres + seed multi-tenant. Bloquea cualquier re-ejecución de NT-016/M2-QA2 hasta refrescar credenciales a usuarios CocoUAT (`mariano.carretero`, `angel.montemayor`, `santino.im`, `kevin.esquivel` con password `Fuego2026!`). Cascada: 39/46 assertions de la colección quedan en rojo. Aunque la sesión es M2, se clasifica bajo M1 porque la colección M1-Fiscal también podría sufrir el mismo drift si se intenta re-ejecutar (hereda el patrón de credenciales). |
| BUG-M1-003 | M1 | Baja | Suite E2E `satConsultaService.e2e.test.js` queda omitido por falta de CFDIs reales con UUID vivo | M1-QA4 — sección "Nota importante sobre los datos de prueba" | Abierto | `2026-04-20_M1-QA4-pruebas-cfdi-sat.md` | Toda la validación del servicio `satConsultaService` se hizo con mocks SOAP. El contrato real contra `ConsultaCFDIService.svc` no se ha verificado contra producción. Pendiente: obtener un set de UUIDs con timbres vigentes y cancelados para ejecutar `bun run test:e2e` con `RUN_REAL_SAT_TESTS=1`. No bloquea la entrega de M1 porque la cobertura unitaria con mocks es exhaustiva (15 códigos de error CFDI + 5 variantes de payload SOAP). |

## Defectos cerrados antes de v2.0 (referencia histórica)

Ningún defecto previo cerrado: este es el primer corte formal del log. Las observaciones
documentadas en `2026-03-27_dt007-test-cases-s3.md` (riesgo de seguridad cross-org en
`fileController.downloadFile`) no se han clasificado como BUG porque están registradas
como **caso de prueba pendiente** (TC-S3-004) y no como defecto detectado en ejecución.

## Próximos cortes

- **v3.0 (NT-021)** — añadirá defectos M2 (workflow autorización, granular permissions)
  y M3 (API Keys, export contable, onboarding).
- Cuando un BUG cambie de estatus, edítese **aquí** y refleje el cambio en la próxima
  versión del Plan de Pruebas (no se modifican `.docx` ya firmados).
