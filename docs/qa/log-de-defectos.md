# Log de Defectos — Plan de Pruebas

> Fuente única de verdad. Cada defecto vive aquí; las sesiones de QA referencian por ID.
> Este archivo se referencia desde `Plan de Pruebas de Software v4.0.docx` (§7.4)
> y se va extendiendo con cada módulo. El corte actual cubre M1, M2 y M3, más las
> correcciones de seguimiento posteriores a M2 (defecto crítico F1 y reclasificación
> de BUG-M2-003).

## Convenciones

- **ID**: `BUG-<modulo>-<NNN>` (ej. `BUG-M1-001`).
- **Severidad**: Crítica / Alta / Media / Baja (matriz §7.1 del Plan de Pruebas).
- **Estatus**: Abierto / En revisión / Resuelto / Cerrado / Reabierto.
- **Sesión origen**: nombre del reporte de sesión QA que detectó el defecto.

## Resumen por severidad (corte 2026-06-02, Módulos 1 + 2 + 3 + seguimientos)

| Severidad | M1 | M2 | M3 + Seguimientos | Total |
|---|---:|---:|---:|---:|
| Crítica | 0 | 0 | 1 | 1 |
| Alta | 0 | 1 | 0 | 1 |
| Media | 2 | 3 | 1 | 6 |
| Baja | 1 | 0 | 0 | 1 |
| **Total** | **3** | **4** | **2** | **9** |

> **Nota:** la columna *M3 + Seguimientos* agrupa `BUG-M3-001` (catálogo contable, Media,
> resuelto) y el defecto crítico `F1` (`POST /api/organizations` 500, resuelto), detectado
> en el seguimiento cross-module TI-001. Estatus al corte: **4 resueltos/cerrados**
> (F1, BUG-M3-001, BUG-M2-003, BUG-M1-001) y **5 abiertos** (BUG-M1-002, BUG-M1-003,
> BUG-M2-001, BUG-M2-002, BUG-M2-004). Ninguna severidad Crítica o Alta de producto
> permanece abierta (BUG-M2-004 es deuda de proceso, mitigada).

## Tabla

| ID | Módulo | Severidad | Título | Caso / Endpoint | Estatus | Sesión origen | Notas |
|----|--------|-----------|--------|-----------------|---------|---------------|-------|
| BUG-M1-001 | M1 | Media | Endpoint `GET /comprobantes/:id/validacion-sat` no existe como ruta independiente | NT-006 — Postman M1 Fiscal, request "GET validacion-sat" | Cerrado (no-fix) | `2026-04-20_nt-006-postman-m1-fiscal.md` | La validación SAT está integrada dentro de `POST /api/comprobantes/:receipt_id` (PR #31, `feat/full/sat-cfdi-consulta`). Se documentó como decisión de producto; la colección Postman valida `sat_estado` en la respuesta del POST. 5/6 endpoints originales del spec NT-006 están cubiertos. |
| BUG-M1-002 | M1 | Media | Pre-request de colección Postman M2 usa credenciales seed obsoletas (era MariaDB) | NT-016 re-ejecución 2026-05-27, 4 logins en pre-request fallan con 401 | Abierto | `2026-05-27_nt-016-postman-m2-verification.md` | Drift de fixture: la colección hardcodea `admin/admin123`, `andres.gomez/andres123`, `laura.flores/laura321`, `diego.hernandez/diego654`. Estos usuarios desaparecieron cuando el stack migró a Postgres + seed multi-tenant. Bloquea cualquier re-ejecución de NT-016/M2-QA2 hasta refrescar credenciales a usuarios CocoUAT (`mariano.carretero`, `angel.montemayor`, `santino.im`, `kevin.esquivel` con password `Fuego2026!`). Cascada: 39/46 assertions de la colección quedan en rojo. Aunque la sesión es M2, se clasifica bajo M1 porque la colección M1-Fiscal también podría sufrir el mismo drift si se intenta re-ejecutar (hereda el patrón de credenciales). |
| BUG-M1-003 | M1 | Baja | Suite E2E `satConsultaService.e2e.test.js` queda omitido por falta de CFDIs reales con UUID vivo | M1-QA4 — sección "Nota importante sobre los datos de prueba" | Abierto | `2026-04-20_M1-QA4-pruebas-cfdi-sat.md` | Toda la validación del servicio `satConsultaService` se hizo con mocks SOAP. El contrato real contra `ConsultaCFDIService.svc` no se ha verificado contra producción. Pendiente: obtener un set de UUIDs con timbres vigentes y cancelados para ejecutar `bun run test:e2e` con `RUN_REAL_SAT_TESTS=1`. No bloquea la entrega de M1 porque la cobertura unitaria con mocks es exhaustiva (15 códigos de error CFDI + 5 variantes de payload SOAP). |
| BUG-M2-001 | M2 | Media | `POST /api/admin/roles//permissions` devuelve 404 — variable `role_id_solicitante` vacía en pre-request Postman | M2-QA2 — Newman / Role Assignment / Assign permission to role | Abierto | `2026-05-27_M2-QA2-workflow-aprobacion.md` | El folder Role Assignment de `M2-Authorization.postman_collection.json` no resuelve `{{role_id_solicitante}}` antes del request, generando una URL malformada `…/roles//permissions`. Falta un request previo `GET /api/admin/roles?nombre=solicitante` (o un pre-request por folder) que cachee el `role_id` real en una variable de colección. Mientras no se arregle, 1 de las 2 assertions del folder queda en rojo. |
| BUG-M2-002 | M2 | Media | `DELETE /api/admin/roles//permissions/{id}` devuelve 404 por el mismo drift de variable | M2-QA2 — Newman / Role Assignment / Revoke permission from role | Abierto | `2026-05-27_M2-QA2-workflow-aprobacion.md` | Variante de BUG-M2-001 sobre el verbo DELETE. Misma causa raíz (`role_id_solicitante` vacía) y misma corrección (pre-request o request previo de lookup). Cuenta como 1 assertion roja adicional del folder Role Assignment. |
| BUG-M2-003 | M2 | Media | `PUT /api/authorizer/authorize-travel-request/{request_id}/{n1_user_id}` devuelve 400 cuando N1 (`santino.im`) intenta aprobar solicitud creada por `angel.montemayor` | M2-QA2 — Newman / Workflow Happy path / Approve N1 | Resuelto | `2026-05-27_M2-QA2-workflow-aprobacion.md` | **Reclasificado (2026-06-02): NO es defecto de backend.** Diagnóstico empírico: `approverResolver` resuelve correcto (`angel.montemayor` → `santino.im` N1 → `kevin.esquivel` N2). Además, el motor de workflow **salta N1 para montos ≤ $50k** (`skipApplied:true`, `levels:[2]`), por lo que la solicitud de $1500 del happy-path **no tenía etapa N1** → 400 esperado. El rojo era **drift de diseño del fixture Postman** (monto que salta N1 + `role_id_solicitante` sin resolver), misma familia que BUG-M2-001/002. **Fix:** colección corregida (monto > $50k + resolución dinámica de `role_id_solicitante`) → Newman **46/46** (PR backend #99). Regresión del resolver: `tests/services/approverResolver.cocouat.test.js` (PR #98). |
| BUG-M2-004 | M2 | Alta | Suite e2e `refundRules.e2e.test.js` ejecuta `resetPostgres()` (TRUNCATE CASCADE) y destruye el seed CocoUAT | M2-QA2 — `tests/routes/refundRules.e2e.test.js`, bloqueo posterior de 4 escenarios manuales | Abierto | `2026-05-27_M2-QA2-workflow-aprobacion.md` | La suite ejecuta `TRUNCATE TABLE … RESTART IDENTITY CASCADE` en `beforeAll`/`beforeEach`, lo que vacía las tablas con los usuarios CocoUAT. Cualquier flujo posterior basado en HTTP login (Cypress, manual, Newman, otras e2e que asuman seed presente) regresa 401 hasta re-ejecutar `prisma/seed.js`. Bloqueó los 4 escenarios manuales de M2-QA2 (TC-01..04). Mitigaciones posibles: (a) aislar la BD del e2e en un schema separado, (b) envolver cada test en una transacción con rollback, (c) re-ejecutar `seed.js` en `afterAll`, o (d) usar `pg-mem` para la suite. Este defecto es de "proceso de pruebas", no de producto. |
| F1 | M3 / Cross | Crítica | `POST /api/organizations` devuelve 500 al crear organización (onboarding) | TI-001 — Cypress cross-module, specs F1/F2 | Resuelto | `2026-06-02_followups-3bugs-ci-reconciliacion.md` | Causa raíz: la cadena de bootstrap (`createOrganizationRow` → `bootstrapOrganizationCatalogs` → `ensureOrganizationAdmin`) recibía la instancia global de Prisma en lugar del cliente transaccional `tx`, dejando la escritura de roles fuera de la transacción y del bypass de RLS. **Fix:** propagar `tx` a toda la cadena (PR backend #96). Verificado contra BD viva (organización en estado `CONFIGURING`, 7 roles, admin presente). Restablece el flujo de onboarding y desbloquea los specs F1/F2 de TI-001. |
| BUG-M3-001 | M3 | Media | Catálogo contable sin CRUD expuesto por API (`ChartOfAccount` existe sin rutas REST) | M3-Integration — export contable / catálogo contable | Resuelto | `2026-06-02_followups-3bugs-ci-reconciliacion.md` | Era el único criterio sin endpoint del Newman M3-Integration. **Fix:** nueva API `/api/chart-of-accounts` (servicio, controlador, rutas) bajo permisos `accounting_catalog:read|write`, con guardas de integridad (P2002 → 409, no-borrado si está asociado, validación de `parentAccountId` + prevención de ciclos, borrado lógico). PR backend #97. Verificado con 5/5 specs e2e. Cierra US-24. |

## Defectos cerrados antes de v2.0 (referencia histórica)

Ningún defecto previo cerrado: este es el primer corte formal del log. Las observaciones
documentadas en `2026-03-27_dt007-test-cases-s3.md` (riesgo de seguridad cross-org en
`fileController.downloadFile`) no se han clasificado como BUG porque están registradas
como **caso de prueba pendiente** (TC-S3-004) y no como defecto detectado en ejecución.

## Próximos cortes

- **v3.0 (NT-021)** — incluyó los defectos M2 (workflow autorización, granular permissions).
- **v4.0 (cierre M3 + seguimientos, 2026-06-02)** — incorpora `BUG-M3-001` (catálogo
  contable CRUD, resuelto vía la nueva API `/api/chart-of-accounts`) y el defecto crítico
  `F1` (`POST /api/organizations` 500, resuelto), además de reclasificar `BUG-M2-003` a
  Media y marcarlo resuelto tras corregir la colección Postman (Newman 46/46). Reflejado
  en `Plan de Pruebas de Software v4.0.docx` (§7.4 y nuevo Anexo M3).
- Cuando un BUG cambie de estatus, edítese **aquí** y refleje el cambio en la próxima
  versión del Plan de Pruebas (no se modifican `.docx` ya firmados).
