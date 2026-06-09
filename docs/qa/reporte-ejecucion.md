# Reporte Consolidado de Ejecución de Pruebas

> **Corte:** 2026-06-02 · **Responsable:** Erick Morales (QA) · **Alcance:** Módulos 1, 2 y 3.
>
> Este documento es la **fuente canónica del estado de ejecución** (columna *Estado*) de la
> [Matriz de Trazabilidad](matriz-trazabilidad.md). Consolida los resultados de las corridas
> automatizadas y manuales a partir de evidencia versionada. **No se inventan resultados pass/fail:**
> cada estado se respalda con un artefacto citado. Los conteos de cobertura y de tests, al ser
> dinámicos, se referencian contra [`testing.md`](testing.md) como fuente viva.

---

## 1. Resumen ejecutivo

| Indicador | Resultado | Meta | Veredicto |
|---|---|---|---|
| Cobertura backend (stmts/lines) | **93.1%** | 80% | Supera |
| Cobertura frontend (stmts/lines) | **87.75%** / **90.28%** (2026-06-02) | 70% | Supera |
| Suite backend (Jest) | **430/431** (1 skip, 0 fallos) con stack arriba | — | |
| Newman M2-Authorization | **46/46** assertions (100%) | — | Corregido en PR #99 (run original 42/46) |
| Newman M3-Integration | **29/29** assertions (100%) | — | |
| Cypress TI-001 (cross-module) | **3/5** specs verdes | — | F3/F4/F5 verdes; F1/F2 desbloqueados tras PR #96 (F1 resuelto), re-ejecución pendiente de merge |
| Casos manuales M1 | **210/210** | — | |
| Defectos (log formal) | **9** total · **5 abiertos** / **4 resueltos-cerrados** | — | 0 Crítica/Alta de producto abierta |

> La cobertura y el conteo de tests provienen de la medición real del 2026-06-02 documentada en
> [`testing.md` sección 1](testing.md). El frontend **superó la meta de 70%** tras ampliar las pruebas de
> `OnboardingImportAdmin` (14%→~87%), `FileDropZone` (38%→93%) y `XmlExpenseForm` (45%→92%);
> ver `testing.md` para el valor vigente.

---

## 2. Automatización backend (Jest + Supertest)

Corrida verde verificada el 2026-06-02 con el stack Docker levantado (Postgres 16 +
LocalStack) + `prisma db push` + seed: **430/431 pasan (1 skip), 0 fallos, cobertura 93.1%**.
Sin el stack, dos suites de integración (`requestCommentController.test.js`, `cfdiComprobantes.test.js`)
no conectan a Postgres (`PrismaClientInitializationError`) — es dependencia de entorno, **no son
regresiones**. Detalle e inventario por carpeta en [`testing.md`](testing.md).

### 2.1 Suites E2E backend (Jest e2e)

| Suite | Cubre | Resultado | Evidencia |
|---|---|---|---|
| `apiKeys.e2e.test.js` | Ciclo de vida de API Keys (M3) | **2/2** | `tests/routes/apiKeys.e2e.test.js` (rama `test/qa/m3-qa2-api-keys-export`, pendiente de merge) |
| `accountingExport.e2e.test.js` | Exportación contable + gate RBAC (M3) | **5/5** | `tests/services/accountingExport/accountingExport.e2e.test.js` |
| `refundRules.e2e.test.js` | Reglas de reembolso, políticas, inbox (M2-006) | Pasa en aislamiento | Ver [BUG-M2-004](log-de-defectos.md) |
| `verification-cfdi.e2e.test.js` | Verificación CFDI con mock SAT (M1) | Realizado | Ver sección 4 (matriz CFDI) |
| `exchangeRate.e2e.test.js` | Tipo de cambio Banxico/BER (M1) | Realizado | Ver sección 4 (matriz BER) |

> **`refundRules.e2e.test.js`** ejecuta `TRUNCATE … RESTART IDENTITY CASCADE` en su ciclo de
> vida y **destruye el seed CocoUAT**, bloqueando cualquier flujo posterior basado en login HTTP.
> Es deuda de **proceso de pruebas** (aislamiento de BD), no de producto. Ver [BUG-M2-004](log-de-defectos.md).

---

## 3. Automatización de API (Postman / Newman)

### 3.1 M2 — `M2-Authorization` · 46/46 assertions (100%, corregido)

24 requests · 46 assertions. La corrida original (2026-05-27) tuvo **4 rojas**; las 4 se corrigieron en **PR #99** → **46/46**. Evidencia de la corrida original: [`evidencias/newman/M2-QA2-newman-report.json`](evidencias/newman/M2-QA2-newman-report.json).

| Assertion roja | Causa raíz | Defecto |
|---|---|---|
| `Approve N1` | **No es bug de backend:** el resolver resuelve santino como N1; el workflow salta N1 para ≤ $50k, y el happy-path Postman usaba $1500 (sin etapa N1) → 400. Drift de fixture, corregido (PR #99, Newman 46/46). | [BUG-M2-003](log-de-defectos.md) (Media) |
| `Assign permission to role` | Variable `role_id_solicitante` vacía en pre-request → URL `…/roles//permissions` (404). Drift de colección, no del backend. | [BUG-M2-001](log-de-defectos.md) (Media) |
| `Revoke permission from role` | Misma causa que la anterior, verbo DELETE. | [BUG-M2-002](log-de-defectos.md) (Media) |

> Las **4 rojas eran drift de la colección Postman** (variables/credenciales/fixture de monto), no del
> backend: la resolución del aprobador N1 (BUG-M2-003) resultó correcta tras el diagnóstico empírico y
> se reclasificó de Alta a Media. Las 4 se corrigieron en **PR #99** (resolución dinámica de
> `role_id_solicitante` + monto que sí dispara la etapa N1) → **Newman 46/46**.

### 3.2 M3 — `M3-Integration` · 29/29 assertions (100%)

14 requests · 29 assertions · **0 rojas**. Evidencia: [`evidencias/newman/M3-QA2-newman-report.json`](evidencias/newman/M3-QA2-newman-report.json).

Cobertura por criterio de aceptación (API Keys + exportación contable, M3):

| Criterio | Resultado | Evidencia |
|---|---|---|
| Ciclo de vida API Key (generar → consumir → logs → revocar → 401) | OK | Folder Postman "API Keys lifecycle" + `apiKeys.e2e.test.js` |
| Listar / auditar API Keys por organización | OK | `GET /api/keys/org/:orgId`, `GET /api/keys/:id/logs` |
| Export contable JSON/XML (`/api/export/contable`) | OK | Folder "Export contable" + `export.e2e.test.js` |
| Gate `requireAuth(["Cuentas por pagar"])` (admin → 403) | OK | Postman + `export.e2e.test.js` |
| Re-export con `status=Sincronizado` | OK | `export.e2e.test.js` |
| External export con `X-API-Key` (key revocada → 401) | OK | Folder "External export" |
| **Catálogo contable CRUD por organización** | 5/5 e2e | Nueva API `/api/chart-of-accounts` (PR #97); [BUG-M3-001](log-de-defectos.md) resuelto, cierra US-24 |

> **Resuelto (2026-06-02):** se expuso el CRUD del catálogo contable como API REST
> `/api/chart-of-accounts` (servicio, controlador y rutas) bajo permisos `accounting_catalog:read|write`,
> con guardas de integridad (P2002 → 409, no-borrado si está asociado, validación de `parentAccountId`
> + prevención de ciclos, borrado lógico). Verificado con **5/5 specs e2e**. Cierra **US-24** y
> **BUG-M3-001** (PR backend #97).

---

## 4. Integraciones críticas — E2E con mocks

### 4.1 Verificación CFDI ante el SAT (NT-009)

Fuente: [`cfdi.e2e.test.md`](cfdi.e2e.test.md).

| Carril | Resultado |
|---|---|
| Contrato SAT (mock server SOAP) | **15/15 Realizado** |
| Endpoint + DB E2E | **12 Realizado / 3 Omitido** |

Los 3 omitidos son **límites de diseño documentados**, no fallos: `TC-002` y `TC-009` (el endpoint
no envía `fe`/`selloUltimos8`) y `TC-010` (el endpoint siempre emite `tt` con 2 decimales). La
validación contra **SAT real** está diferida como carril opcional (`RUN_REAL_SAT_TESTS=1`) por falta
de UUIDs con timbres vigentes — [BUG-M1-003](log-de-defectos.md) (Baja, no bloquea M1).

### 4.2 Tipo de cambio Banxico (NT-010 / BER)

Fuente: [`ber-bmx.e2e.test.md`](ber-bmx.e2e.test.md). **30/30 casos Activo, 0 skip** (Happy path,
Not Found, Fallback DOF, Cache, validación de monedas, contrato de endpoints).

---

## 5. E2E de frontend (Cypress)

### 5.1 TI-001 — Flujo completo cross-module · 3/5 verdes (F1/F2 desbloqueados)

Evidencia: [`evidencias/cypress/TI-001-2026-05-27-summary.md`](evidencias/cypress/TI-001-2026-05-27-summary.md) (corrida 2026-05-27, previa a la corrección de F1).

| Spec | Resultado |
|---|---|
| F1 — Admin Ditta crea organización | → Bug de producto **resuelto** (PR #96); desbloqueado |
| F2 — Impersonación de la org nueva | → Dependía de F1; **desbloqueado** tras PR #96 |
| F3 — Sync de empleados consultable | |
| F4 — Solicitante crea solicitud + parsea CFDI | |
| F5 — N1 aprueba → N2 finaliza → CxP consulta export | |

> **F1 fue un defecto de producto crítico, ya RESUELTO (PR backend #96):** `POST /api/organizations`
> devolvía 500 porque la cadena de bootstrap recibía la instancia global de Prisma en lugar del cliente
> transaccional `tx`, dejando la escritura de roles fuera de la transacción con bypass de RLS
> (`Role "Administrador" not found for org N`). El fix propaga `tx` por toda la cadena; verificado
> contra BD viva (organización en `CONFIGURING`, 7 roles, admin presente). F1 y F2 quedan
> **desbloqueados**; la re-ejecución verde de TI-001 queda pendiente del merge del PR. La evidencia
> citada (2026-05-27) refleja la corrida previa a la corrección.

### 5.2 Suite Cypress + Vitest

262 tests Vitest (24 archivos) y 16 specs Cypress catalogados en [`testing.md` sección 4](testing.md). El frontend CI
**hoy no ejecuta Vitest/Cypress** (solo typecheck/build/audit) — ver sección 7.

---

## 6. Pruebas manuales

| Bloque | Resultado | Fuente |
|---|---|---|
| M1 (Fiscal) — casos manuales/funcionales | **210/210** | Plan de Pruebas v4.0, Anexo M1 |
| M2-006 (motor de reglas de reembolso) | Casos `M2-006-01..16` diseñados (RF-37..46) | [`m2-006-casos-de-prueba.md`](m2-006-casos-de-prueba.md) |
| M2 — escenarios manuales de ejecución | **0/4 bloqueados** por seed wipe del e2e | [BUG-M2-004](log-de-defectos.md) |
| DT-007 — Almacenamiento S3 | `TC-S3-001..005` diseñados | Entregable `Casos_de_prueba/` (pendiente de migrar a wiki) |
| Sistema legado (10 cambios) | Caja blanca/negra + `TC-01..TC-09` | [`documentacion-pruebas-caja-negra.md`](documentacion-pruebas-caja-negra.md) (NT-003) |

> La cobertura funcional de M2 se sostiene en la automatización (Newman **46/46** tras corregir la
> colección M2-Authorization —ver [BUG-M2-003](log-de-defectos.md), antes 42/46— + suites Jest de
> políticas/categorías/plazos/excepciones/escalamiento, incluidas en la corrida 430/431); los 4
> escenarios manuales quedaron bloqueados por el seed wipe del e2e, no por la lógica de negocio.

---

## 7. Defectos y deuda de proceso

### 7.1 Log formal de defectos

Fuente única de verdad: [`log-de-defectos.md`](log-de-defectos.md) (corte 2026-06-02, M1 + M2 + M3 + seguimientos).

| Severidad | Abiertos | Resueltos/Cerrados | IDs |
|---|---:|---:|---|
| Crítica | 0 | 1 | *resuelto:* F1 (`POST /api/organizations` 500, PR #96) |
| Alta | 1 | 0 | BUG-M2-004 (TRUNCATE e2e — deuda de proceso, ver sección 7.3) |
| Media | 3 | 3 | *abiertos:* BUG-M2-001/002 (drift colección Postman, fix en PR #99), BUG-M1-002 (cred drift) · *resueltos:* BUG-M2-003 (reclasif. + PR #99), BUG-M3-001 (API catálogo, PR #97) · *cerrado:* BUG-M1-001 |
| Baja | 1 | 0 | BUG-M1-003 (SAT real diferido) |
| **Total** | **5** | **4** | **9 defectos** |

### 7.2 Defectos de seguimiento (ya en el log formal y resueltos)

Todos los defectos detectados están incorporados al log formal (sección 7.1 / [`log-de-defectos.md`](log-de-defectos.md)).
Los dos defectos de seguimiento posteriores al corte M2 ya están **resueltos**:

| ID | Severidad | Descripción | Estado |
|---|---|---|---|
| **F1** (producto) | **Crítica** | `POST /api/organizations` → 500 (cliente Prisma global fuera de la tx de bootstrap → roles fuera de RLS) | **Resuelto** (PR backend #96); restablece onboarding |
| **BUG-M3-001** | Media | Catálogo contable sin CRUD expuesto por API | **Resuelto** (PR backend #97, API `/api/chart-of-accounts`, 5/5 e2e, cierra US-24) |

### 7.3 Deuda de proceso (no son defectos de producto)

- **Aislamiento de BD en e2e:** `refundRules.e2e.test.js` borra el seed (BUG-M2-004). Mitigar con
  schema aislado, rollback transaccional o reseed idempotente.
- **Drift de credenciales Postman:** la colección M2 referenciaba usuarios seed legados (MariaDB);
  refrescar a usuarios CocoUAT (BUG-M1-002).
- **Frontend CI no ejecuta pruebas:** agregar `bun run test` (Vitest) y un smoke de Cypress al workflow.
- **`expenseSettlement.test.ts`** queda fuera del `include` de Vitest (no se ejecuta en `bun run test`).

---

## 8. Trazabilidad

El mapeo requisito → caso de prueba → estado → evidencia vive en la
[Matriz de Trazabilidad](matriz-trazabilidad.md) (US-01..US-25 + 10 cambios al legado). Este reporte
es la fuente de su columna *Estado*.

---

## Fuentes

- [`testing.md`](testing.md) — inventario de tests y cobertura medida (fuente viva).
- [`evidencias/newman/M2-QA2-newman-report.json`](evidencias/newman/M2-QA2-newman-report.json) y [`M3-QA2-newman-report.json`](evidencias/newman/M3-QA2-newman-report.json) — salidas Newman.
- [`evidencias/cypress/TI-001-2026-05-27-summary.md`](evidencias/cypress/TI-001-2026-05-27-summary.md) — reporte Cypress cross-module + captura.
- [`cfdi.e2e.test.md`](cfdi.e2e.test.md) y [`ber-bmx.e2e.test.md`](ber-bmx.e2e.test.md) — matrices E2E de integraciones.
- [`log-de-defectos.md`](log-de-defectos.md) — registro unificado de defectos.
- [`m2-006-casos-de-prueba.md`](m2-006-casos-de-prueba.md) — casos manuales M2-006 (RF-37..46).
- `plan-de-pruebas/Plan de Pruebas de Software v4.0.docx` — Plan de Pruebas (Anexo M1 + Anexo M2 + Anexo M3 + Anexo Tendencias; secciones 1–14, sección 11 Entregables).
- Suites E2E de backend: `tests/services/accountingExport/accountingExport.e2e.test.js` (export contable) y `tests/routes/apiKeys.e2e.test.js` (API Keys, en la rama `test/qa/m3-qa2-api-keys-export` pendiente de merge).
