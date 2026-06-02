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
| Cobertura backend (stmts/lines) | **93.1%** | 80% | ✅ Supera |
| Cobertura frontend (stmts) | **50.67%** (2026-06-02) | 70% | 🟡 En mejora activa |
| Suite backend (Jest) | **430/431** (1 skip, 0 fallos) con stack arriba | — | ✅ |
| Newman M2-Authorization | **42/46** assertions (91.3%) | — | 🟡 4 rojas (analizadas) |
| Newman M3-Integration | **29/29** assertions (100%) | — | ✅ |
| Cypress TI-001 (cross-module) | **3/5** specs | — | 🟡 2 bloqueados por bug de producto |
| Casos manuales M1 | **210/210** | — | ✅ |
| Defectos abiertos (log formal) | **6** (2 Alta, 4 Media) + 1 cerrado | — | 🟡 |

> La cobertura y el conteo de tests provienen de la medición real del 2026-06-02 documentada en
> [`testing.md` §1](testing.md). El frontend está por debajo de meta y en proceso activo de
> incrementarse (componentes de mayor peso sin cubrir); ver `testing.md` para el valor vigente.

---

## 2. Automatización backend (Jest + Supertest)

Corrida verde verificada el 2026-06-02 con el stack Docker levantado (Postgres 16 + Mongo 7 +
LocalStack) + `prisma db push` + seed: **430/431 pasan (1 skip), 0 fallos, cobertura 93.1%**.
Sin el stack, dos suites de integración (`requestCommentController.test.js`, `cfdiComprobantes.test.js`)
no conectan a Postgres (`PrismaClientInitializationError`) — es dependencia de entorno, **no son
regresiones**. Detalle e inventario por carpeta en [`testing.md`](testing.md).

### 2.1 Suites E2E backend (Jest e2e)

| Suite | Cubre | Resultado | Evidencia |
|---|---|---|---|
| `apiKeys.e2e.test.js` | Ciclo de vida de API Keys (M3) | **2/2** ✅ | `TC3005B.501-Backend/tests/routes/apiKeys.e2e.test.js` |
| `export.e2e.test.js` | Exportación contable + gate RBAC (M3) | **5/5** ✅ | `TC3005B.501-Backend/tests/routes/export.e2e.test.js` |
| `refundRules.e2e.test.js` | Reglas de reembolso, políticas, inbox (M2-006) | Pasa en aislamiento ⚠️ | Ver [BUG-M2-004](log-de-defectos.md) |
| `verification-cfdi.e2e.test.js` | Verificación CFDI con mock SAT (M1) | Realizado | Ver §4 (matriz CFDI) |
| `exchangeRate.e2e.test.js` | Tipo de cambio Banxico/BER (M1) | Realizado | Ver §4 (matriz BER) |

> ⚠️ **`refundRules.e2e.test.js`** ejecuta `TRUNCATE … RESTART IDENTITY CASCADE` en su ciclo de
> vida y **destruye el seed CocoUAT**, bloqueando cualquier flujo posterior basado en login HTTP.
> Es deuda de **proceso de pruebas** (aislamiento de BD), no de producto. Ver [BUG-M2-004](log-de-defectos.md).

---

## 3. Automatización de API (Postman / Newman)

### 3.1 M2 — `M2-Authorization` · 42/46 assertions (91.3%)

24 requests · 46 assertions · **4 rojas**. Evidencia: [`evidencias/newman/M2-QA2-newman-report.json`](evidencias/newman/M2-QA2-newman-report.json).

| Assertion roja | Causa raíz | Defecto |
|---|---|---|
| `Approve N1` | El servicio no resuelve a `santino.im` como N1 designado para una solicitud de `angel.montemayor` (N2 sí aprueba bien). Bug real de routing. | [BUG-M2-003](log-de-defectos.md) (Alta) |
| `Assign permission to role` | Variable `role_id_solicitante` vacía en pre-request → URL `…/roles//permissions` (404). Drift de colección, no del backend. | [BUG-M2-001](log-de-defectos.md) (Media) |
| `Revoke permission from role` | Misma causa que la anterior, verbo DELETE. | [BUG-M2-002](log-de-defectos.md) (Media) |

> De las 4 rojas, **3 son drift de la colección Postman** (variables/credenciales) y **1 es un
> defecto de producto** (resolución de aprobador N1). El backend de asignación/revocación de
> permisos funciona; falla el armado del request.

### 3.2 M3 — `M3-Integration` · 29/29 assertions (100%)

14 requests · 29 assertions · **0 rojas**. Evidencia: [`evidencias/newman/M3-QA2-newman-report.json`](evidencias/newman/M3-QA2-newman-report.json).

Cobertura por criterio de aceptación (API Keys + exportación contable, M3):

| Criterio | Resultado | Evidencia |
|---|---|---|
| Ciclo de vida API Key (generar → consumir → logs → revocar → 401) | ✅ OK | Folder Postman "API Keys lifecycle" + `apiKeys.e2e.test.js` |
| Listar / auditar API Keys por organización | ✅ OK | `GET /api/keys/org/:orgId`, `GET /api/keys/:id/logs` |
| Export contable JSON/XML (`/api/export/contable`) | ✅ OK | Folder "Export contable" + `export.e2e.test.js` |
| Gate `requireAuth(["Cuentas por pagar"])` (admin → 403) | ✅ OK | Postman + `export.e2e.test.js` |
| Re-export con `status=Sincronizado` | ✅ OK | `export.e2e.test.js` |
| External export con `X-API-Key` (key revocada → 401) | ✅ OK | Folder "External export" |
| **Catálogo contable CRUD por organización** | ❌ N/A | Endpoint REST no existe ([BUG-M3-001](log-de-defectos.md)) |

> El modelo `ChartOfAccount` existe en `schema.prisma` y lo consume `accountingExportService`, pero
> **no hay rutas/controllers expuestos** en `/api/...`. El criterio queda fuera de validación hasta
> que se exponga la API. Documentado como **BUG-M3-001** (Media).

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

### 5.1 TI-001 — Flujo completo cross-module · 3/5

Evidencia: [`evidencias/cypress/TI-001-2026-05-27-summary.md`](evidencias/cypress/TI-001-2026-05-27-summary.md).

| Spec | Resultado |
|---|---|
| F1 — Admin Ditta crea organización | ❌ FAIL (bug de producto) |
| F2 — Impersonación de la org nueva | ❌ FAIL (depende de F1) |
| F3 — Sync de empleados consultable | ✅ |
| F4 — Solicitante crea solicitud + parsea CFDI | ✅ |
| F5 — N1 aprueba → N2 finaliza → CxP consulta export | ✅ |

> **F1 es un defecto de producto bloqueante (crítico):** `POST /api/organizations` devuelve 500 por
> (a) *sequence stale* (`organizaciones_id_seq.last_value=1` vs `max(id)=101`) y (b) fallo de
> visibilidad RLS en `ensureOrganizationAdmin` (lanza `Role "Administrador" not found for org N`
> aunque el rol existe). Ningún cliente nuevo puede crearse vía API. **Escalado a backend.** F2
> debería pasar sin cambios al spec una vez corregido el backend. Repro mínimo en la evidencia.

### 5.2 Suite Cypress + Vitest

180 tests Vitest ✅ y 16 specs Cypress catalogados en [`testing.md` §4](testing.md). El frontend CI
**hoy no ejecuta Vitest/Cypress** (solo typecheck/build/audit) — ver §7.

---

## 6. Pruebas manuales

| Bloque | Resultado | Fuente |
|---|---|---|
| M1 (Fiscal) — casos manuales/funcionales | **210/210** | Plan de Pruebas v2.0, Anexo M1 |
| M2-006 (motor de reglas de reembolso) | Casos `M2-006-01..16` diseñados (RF-37..46) | [`m2-006-casos-de-prueba.md`](m2-006-casos-de-prueba.md) |
| M2 — escenarios manuales de ejecución | **0/4 bloqueados** por seed wipe del e2e | [BUG-M2-004](log-de-defectos.md) |
| DT-007 — Almacenamiento S3 | `TC-S3-001..005` diseñados | Entregable `Casos_de_prueba/` (pendiente de migrar a wiki) |
| Sistema legado (10 cambios) | Caja blanca/negra + `TC-01..TC-09` | [`documentacion-pruebas-caja-negra.md`](documentacion-pruebas-caja-negra.md) (NT-003) |

> La cobertura funcional de M2 se sostiene en la automatización (Newman 42/46 + suites Jest de
> políticas/categorías/plazos/excepciones/escalamiento, incluidas en la corrida 430/431); los 4
> escenarios manuales quedaron bloqueados por el seed wipe del e2e, no por la lógica de negocio.

---

## 7. Defectos y deuda de proceso

### 7.1 Log formal de defectos

Fuente única de verdad: [`log-de-defectos.md`](log-de-defectos.md) (corte M1 + M2).

| Severidad | Abiertos | Cerrados | IDs |
|---|---:|---:|---|
| Crítica | 0 | 0 | — |
| Alta | 2 | 0 | BUG-M2-003 (routing N1), BUG-M2-004 (TRUNCATE e2e) |
| Media | 3 | 1 | BUG-M2-001/002 (vars Postman), BUG-M1-002 (cred drift) · *cerrado:* BUG-M1-001 |
| Baja | 1 | 0 | BUG-M1-003 (SAT real diferido) |

### 7.2 Defectos detectados pendientes de migrar al log / escalar a producto

| ID | Severidad | Descripción | Acción |
|---|---|---|---|
| **F1** (producto) | **Crítica** | `POST /api/organizations` → 500 (sequence stale + RLS role lookup) | Crear ticket en backend; bloquea onboarding |
| **BUG-M3-001** | Media | Catálogo contable CRUD inexistente (sin rutas REST) | Decidir: exponer API o retirar el criterio |

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
- `plan-de-pruebas/Plan de Pruebas de Software v2.0.docx` — Plan de Pruebas (Anexo M1, §11 Entregables).
- Suites E2E de backend: `TC3005B.501-Backend/tests/routes/apiKeys.e2e.test.js`, `export.e2e.test.js`.
