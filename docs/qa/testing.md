# CocoAPI — Documentación integral de tests automatizados

## 1) Resumen ejecutivo

CocoAPI cuenta con una base de pruebas automatizadas distribuida en dos repositorios:

- **Backend (`TC3005B.501-Backend`)**: 51 archivos de test (Jest + Supertest), con foco fuerte en servicios de negocio, middleware de seguridad, migraciones y flujos E2E críticos (CFDI/SAT, BER, exportación contable, reglas de reembolso).
- **Frontend (`TC3005B.501-Frontend`)**: 40 archivos de test (25 Vitest/RTL + 16 Cypress E2E), con foco en componentes UI, validaciones funcionales y recorridos de usuario por rol.

### Cobertura total medida (2026-06-02)

> Medición real ejecutada el 2026-06-02 con las herramientas de cobertura de cada repo: `jest --coverage` en backend sobre la suite unitaria (excluyendo `*.e2e.test.*`) y `vitest run --coverage` en frontend. Reemplaza las estimaciones por inventario anteriores.

| Capa | Stmts | Branch | Funcs | Lines | Tests | Meta (Plan) |
|---|---:|---:|---:|---:|---|---:|
| Backend | **93.1%** | 87.8% | 94.11% | **93.1%** | 431 (430 , 1 skip, 0 \*) · 47 suites | 80% |
| Frontend | **87.75%** | 82.73% | 88.69% | **90.28%** | 262 · 24 archivos | 70% |

\* **Backend:** corrida **verde con el stack Docker levantado** (`docker compose up postgres localstack` + `prisma db push` + seed) — verificada 2026-06-02: **430/431 pasan** (1 skip), **0 fallos**, cobertura 93.1% (**supera** la meta de 80%). Sin el stack, 2 suites de integración (`requestCommentController.test.js`, `cfdiComprobantes.test.js`, ~15 casos) no conectan a Postgres (`PrismaClientInitializationError`); **no son regresiones**, es dependencia del entorno de pruebas.

**Frontend:** tras ampliar las pruebas de los 3 componentes que más pesaban (2026-06-02), la cobertura subió de ~51% a **87.75% stmts / 90.28% lines** — ahora **supera** la meta de 70% y el run pasa el umbral (`exit 0`). Saltos clave: `views/admin/OnboardingImportAdmin.tsx` 14%→**~87%** (archivo de ~2,238 líneas; +33 tests nuevos), `FileDropZone.tsx` 38%→**93%** (+31), `XmlExpenseForm.tsx` 45%→**92%** (+18). Total: **262 tests** en 24 archivos. La cobertura se mide sobre la lista blanca de 16 componentes (`coverage.include` en `vitest.config.ts`); páginas Astro, stores y utils fuera de esa lista no se contabilizan. Nota: `expenseSettlement.test.ts` queda fuera del `include` de ejecución.

### Frameworks de testing por repositorio

| Repositorio | Unitario/Integración | E2E | Soporte |
|---|---|---|---|
| Backend | Jest | Jest (`*.e2e.test.js`) + Supertest | mocks de módulos, fixtures XML/JSON, mock servers (SAT/Banxico), Prisma test DB |
| Frontend | Vitest + React Testing Library | Cypress | MSW, `@testing-library/user-event`, custom Cypress commands |

### Filosofía general de testing del proyecto

- **Priorizar riesgos de negocio**: autorización, validaciones fiscales (CFDI/SAT), reglas de reembolso y exportación contable.
- **Aislar unidades críticas** con mocks y fixtures controlados.
- **Validar contratos de borde** con integración/E2E (HTTP status, payloads, control de permisos, estados de flujo).
- **Evitar regresiones de UX** con pruebas de componentes y recorridos de usuario por rol.

---

## 2) Estrategia de testing

### Pirámide de testing aplicada

| Nivel | Backend | Frontend | Objetivo |
|---|---|---|---|
| Unitario (base) | Servicios puros y utilidades | Componentes atómicos y utils | Retroalimentación rápida y detección temprana de regresiones lógicas |
| Integración (medio) | Controllers, middleware, Prisma/modelos | Componentes con MSW y estado realista | Validar interacción entre capas |
| E2E (punta) | Flujos API completos | Flujos de usuario con Cypress | Validar experiencia/negocio extremo a extremo |

### Convenciones de nomenclatura

- Backend: `*.test.js`, `*.e2e.test.js`
- Frontend unit/integration: `*.test.ts`, `*.test.tsx`
- Frontend E2E: `*.cy.ts`
- Excepción válida detectada: `tests/services/CDFI/server/test.js` (ejecutable aunque no sigue el sufijo típico de nombre base).

### Ejecución local

#### Backend

```bash
bun run test              # Unit + integración (ignora e2e)
bun run test:watch
bun run test:e2e
bun run test:e2e:watch
bun run test:all
```

#### Frontend

```bash
bun run test              # Vitest
bun run test:watch
bun run test:coverage
bunx cypress open         # E2E interactivo
bunx cypress run          # E2E headless
```

### Ejecución en CI/CD (GitHub Actions)

| Repo | Workflow | Estado actual |
|---|---|---|
| Backend | `.github/workflows/ci.yml` | Ejecuta lint estricto, Prisma validate/format, `bun run test` y sube artifact de cobertura |
| Backend | `.github/workflows/e2e-ci.yml` | Ejecuta `bun run test:e2e --forceExit` con Postgres + LocalStack (S3) de servicios |
| Frontend | `.github/workflows/ci.yml` | Ejecuta typecheck (no bloqueante), build (bloqueante), audit (no bloqueante); **hoy no corre Vitest/Cypress en CI** |
| Ambos | `.github/workflows/pr-checks.yml` | Valida convención de rama y título PR |

---

## 3) Backend — Tests

## 3.1 Configuración y catálogos

### `accountingCatalogs.test.js` -> `accountingCatalogs constants | proveedorFromUserId | formatPstngDate`
- **Archivo**: `TC3005B.501-Backend/tests/config/accountingCatalogs.test.js`
- **Tipo**: unitario
- **Qué hace**: valida constantes contables (sociedad, cuentas, doc types) y formato de proveedor/fecha para exportación SAP-like.
- **Cómo está automatizado**: Jest, pruebas puras de funciones sin I/O.
- **Qué problema resuelve / qué bug previene**: evita pólizas mal formateadas o con claves contables inválidas.
- **Requisitos asociados**: M1 (exportación contable), requiere trazabilidad funcional fina en SRS.

## 3.2 Controllers

### `accountingExportController.test.js` -> `exportByRequest | exportByRange`
- **Archivo**: `TC3005B.501-Backend/tests/controllers/accountingExportController.test.js`
- **Tipo**: integración
- **Qué hace**: valida respuestas JSON/XML, validación de fechas y mapeo de errores de servicio a HTTP status.
- **Cómo está automatizado**: Jest con `jest.unstable_mockModule`, `beforeEach`, spies de `console.error`.
- **Qué problema resuelve / qué bug previene**: evita respuestas inconsistentes (200/400/404/409/500) y fallas de negociación de contenido.
- **Requisitos asociados**: M1-010.

### `adminController.employeeSync.test.js` -> `adminController.syncEmployee`
- **Archivo**: `TC3005B.501-Backend/tests/controllers/adminController.employeeSync.test.js`
- **Tipo**: integración
- **Qué hace**: prueba éxito, falta de `organization_id` y propagación de errores del servicio.
- **Cómo está automatizado**: Jest + mocks de `employeeSyncService`.
- **Qué problema resuelve / qué bug previene**: evita sincronizaciones parciales/incorrectas en administración de empleados.
- **Requisitos asociados**: módulo de administración de usuarios/empleados.

### `requestCommentController.test.js` -> `POST/GET comments`
- **Archivo**: `TC3005B.501-Backend/tests/controllers/requestCommentController.test.js`
- **Tipo**: integración
- **Qué hace**: valida creación/listado de comentarios con auth, autorización por usuario y paginación.
- **Cómo está automatizado**: Jest + Supertest, DB de prueba con Prisma, token de prueba.
- **Qué problema resuelve / qué bug previene**: evita comentarios no autorizados y resultados inconsistentes en historial conversacional.
- **Requisitos asociados**: colaboración sobre solicitudes.
- **Nota skip/todo**: contiene `it.skip` y comentario TODO (`Update later to suport new encryption`).

## 3.3 Middleware y seguridad

### `authMiddleware.test.js` -> `authenticateToken | authorizeRole | requireAuth | authErrors`
- **Archivo**: `TC3005B.501-Backend/tests/middleware/authMiddleware.test.js`
- **Tipo**: integración
- **Qué hace**: valida JWT válido/inválido/expirado, roles y bypass controlado en dev.
- **Cómo está automatizado**: Jest + `jsonwebtoken`, mocks de req/res/next.
- **Qué problema resuelve / qué bug previene**: previene accesos indebidos y manejo inconsistente de errores de auth.
- **Requisitos asociados**: seguridad/autenticación.

### `fileUpload.test.js` -> `handleMulterError | upload middleware`
- **Archivo**: `TC3005B.501-Backend/tests/middleware/fileUpload.test.js`
- **Tipo**: integración
- **Qué hace**: valida MIME types permitidos, límites de tamaño y mapeo de errores Multer.
- **Cómo está automatizado**: Jest + Supertest + app Express de prueba + payloads binarios.
- **Qué problema resuelve / qué bug previene**: evita carga de archivos peligrosos/incorrectos y mensajes de error ambiguos.
- **Requisitos asociados**: carga de comprobantes.

### `permissionMiddleware.test.js` -> `loadPermissions | authorizePermission | authorizeAnyPermission`
- **Archivo**: `TC3005B.501-Backend/tests/middleware/permissionMiddleware.test.js`
- **Tipo**: integración
- **Qué hace**: valida semántica AND/OR de permisos y composición de middlewares.
- **Cómo está automatizado**: Jest + mocks de `permissionService`.
- **Qué problema resuelve / qué bug previene**: evita exposiciones de rutas por autorización mal aplicada.
- **Requisitos asociados**: modelo de permisos granular.

### `tenantContext.test.js` -> `tenantContextMiddleware | withTenantContext`
- **Archivo**: `TC3005B.501-Backend/tests/middleware/tenantContext.test.js`
- **Tipo**: integración
- **Qué hace**: valida inyección de tenant por JWT y override controlado para ROOT.
- **Cómo está automatizado**: Jest con req/res simulados.
- **Qué problema resuelve / qué bug previene**: reduce riesgo de fuga de datos entre organizaciones.
- **Requisitos asociados**: multi-tenant.

## 3.4 Migraciones y Prisma

### `approvalSubstitutesMigration.test.js` -> `M2-006 SQL up/down`
- **Archivo**: `TC3005B.501-Backend/tests/migrations/approvalSubstitutesMigration.test.js`
- **Tipo**: integración
- **Qué hace**: valida estructura SQL de `approval_substitutes` y reversión.
- **Cómo está automatizado**: Jest, aserciones sobre contenido SQL.
- **Qué problema resuelve / qué bug previene**: evita drift de esquema y rollbacks incompletos.
- **Requisitos asociados**: M2-006.

### `cfdiComprobantesMigration.test.js` -> `M1-001 SQL up/down`
- **Archivo**: `TC3005B.501-Backend/tests/migrations/cfdiComprobantesMigration.test.js`
- **Tipo**: integración
- **Qué hace**: verifica creación de tablas/constraints CFDI y rollback.
- **Cómo está automatizado**: Jest con aserciones regex.
- **Qué problema resuelve / qué bug previene**: evita migraciones fiscales defectuosas.
- **Requisitos asociados**: M1-001.

### `workflowRulesMigration.test.js` -> `M2-004 SQL up/down`
- **Archivo**: `TC3005B.501-Backend/tests/migrations/workflowRulesMigration.test.js`
- **Tipo**: integración
- **Qué hace**: valida artefactos de reglas de workflow y eliminación al revertir.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita inconsistencias en snapshots/columnas de aprobación.
- **Requisitos asociados**: M2-004.

### `applicantRoleGroups.test.js` -> `ensureApplicantGroupsForRole`
- **Archivo**: `TC3005B.501-Backend/tests/prisma/applicantRoleGroups.test.js`
- **Tipo**: integración
- **Qué hace**: valida creación idempotente de grupos para rol solicitante.
- **Cómo está automatizado**: Jest con prisma mock.
- **Qué problema resuelve / qué bug previene**: evita duplicados o ausencia de permisos base al bootstrap.
- **Requisitos asociados**: seguridad RBAC.

### `bootstrapOrganizationPreview.test.js` -> `getDefaultRolePreviewPermissionCodes`
- **Archivo**: `TC3005B.501-Backend/tests/prisma/bootstrapOrganizationPreview.test.js`
- **Tipo**: integración
- **Qué hace**: valida que roles default incluyan permisos esperados.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita organizaciones nuevas con permisos incompletos.
- **Requisitos asociados**: onboarding de organización.

### `tenantExtension.test.js` -> `applyTenantScopingToArgs`
- **Archivo**: `TC3005B.501-Backend/tests/prisma/tenantExtension.test.js`
- **Tipo**: integración
- **Qué hace**: valida inyección de filtros `organization_id` en operaciones Prisma.
- **Cómo está automatizado**: Jest con pruebas de función pura.
- **Qué problema resuelve / qué bug previene**: evita lecturas/escrituras cross-tenant.
- **Requisitos asociados**: multi-tenant / aislamiento de datos.

## 3.5 Rutas y flujos de reembolso

### `refundRules.e2e.test.js` -> `M2-006 employee-categories | policies | refunds | inbox`
- **Archivo**: `TC3005B.501-Backend/tests/routes/refundRules.e2e.test.js`
- **Tipo**: e2e
- **Qué hace**: valida flujo completo de categorías, políticas, plazos y excepciones de reembolso por API.
- **Cómo está automatizado**: Jest + Supertest + seed Prisma + JWT por rol.
- **Qué problema resuelve / qué bug previene**: evita regresiones en RF de reembolso y autorización por estado.
- **Requisitos asociados**: M2-006.

## 3.6 Servicios de contabilidad

### `accountingExport.e2e.test.js` -> `M1-010 Accounting Export API`
- **Archivo**: `TC3005B.501-Backend/tests/services/accountingExport/accountingExport.e2e.test.js`
- **Tipo**: e2e
- **Qué hace**: valida exportación JSON/XML por solicitud y por rango, incluyendo errores/autorización.
- **Cómo está automatizado**: Jest + Supertest + fixtures DB + parseo XML (`fast-xml-parser`).
- **Qué problema resuelve / qué bug previene**: evita archivos de exportación contable inválidos y errores de control de acceso.
- **Requisitos asociados**: M1-010.

### `accountingExportService.test.js` -> `buildAnticipoPoliza | getPolizasForRequest | getPolizasInRange | polizasToXml`
- **Archivo**: `TC3005B.501-Backend/tests/services/accountingExportService.test.js`
- **Tipo**: integración
- **Qué hace**: valida armado de pólizas AV/GV, validaciones, persistencia de marca exportada y generación XML.
- **Cómo está automatizado**: Jest + mocks de modelo/prisma + transacciones simuladas.
- **Qué problema resuelve / qué bug previene**: previene descuadres contables y duplicidad de exportación.
- **Requisitos asociados**: M1-010.

### `anticipoPolizaLifecycleService.test.js` -> `onTravelRequestFullyApproved | onExpensesVerified`
- **Archivo**: `TC3005B.501-Backend/tests/services/anticipoPolizaLifecycleService.test.js`
- **Tipo**: integración
- **Qué hace**: valida snapshots contables de anticipo en hitos de solicitud.
- **Cómo está automatizado**: Jest con prisma mock.
- **Qué problema resuelve / qué bug previene**: evita pérdida de trazabilidad contable entre etapas.
- **Requisitos asociados**: ciclo de vida de anticipo.

### `cfdiImpuestos.test.js` -> `cfdiTotalsAreCoherent | buildImpuestosFromTaxesBreakdown | glAccountForImpuesto`
- **Archivo**: `TC3005B.501-Backend/tests/services/cfdiImpuestos.test.js`
- **Tipo**: unitario
- **Qué hace**: valida coherencia de impuestos CFDI y mapeo a cuentas contables.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita pólizas/impuestos mal calculados o mal clasificados.
- **Requisitos asociados**: fiscal/contable.

## 3.7 Servicios CFDI / SAT

### `cfdiComprobantes.test.js` -> `POST comprobantes | validacion-sat | validate-receipt`
- **Archivo**: `TC3005B.501-Backend/tests/services/CDFI/cfdiComprobantes.test.js`
- **Tipo**: integración
- **Qué hace**: valida alta de comprobantes, verificación SAT, EFOS y reglas de aprobación/rechazo.
- **Cómo está automatizado**: Jest + Supertest + mocks de servicios SAT/comprobantes/permisos.
- **Qué problema resuelve / qué bug previene**: evita aceptar CFDI inválidos/duplicados o aprobar recibos no válidos fiscalmente.
- **Requisitos asociados**: validación CFDI/SAT.

### `cfdiParser.test.js` -> `parseCFDI | buildComprobanteRegistroBodyFromXml | CfdiParseError`
- **Archivo**: `TC3005B.501-Backend/tests/services/CDFI/cfdiParser.test.js`
- **Tipo**: unitario
- **Qué hace**: valida parseo de CFDI v3.3/v4.0 y clasificación detallada de errores.
- **Cómo está automatizado**: Jest + fixtures XML de casos válidos/malformados.
- **Qué problema resuelve / qué bug previene**: evita ingestión de XML corruptos o con campos fiscales incorrectos.
- **Requisitos asociados**: cumplimiento SAT.

### `satConsultaService.e2e.test.js` -> `SAT live query (opt-in invoices)`
- **Archivo**: `TC3005B.501-Backend/tests/services/CDFI/satConsultaService.e2e.test.js`
- **Tipo**: e2e
- **Qué hace**: consulta SAT para facturas disponibles y valida normalización de respuesta.
- **Cómo está automatizado**: Jest, lectura dinámica de XML reales.
- **Qué problema resuelve / qué bug previene**: detecta incompatibilidades reales de integración SAT.
- **Requisitos asociados**: validación SAT en ambiente real/controlado.

### `satConsultaService.test.js` -> `buildExpresionImpresa | normalizeConsultaResult | acuseToCfdiRow`
- **Archivo**: `TC3005B.501-Backend/tests/services/CDFI/satConsultaService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida construcción de expresión impresa y mapeo normalizado de acuses SAT.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita parseos inconsistentes de estatus SAT.
- **Requisitos asociados**: validación CFDI/SAT.

### `test.js` (SAT mock server) -> `Test mock server`
- **Archivo**: `TC3005B.501-Backend/tests/services/CDFI/server/test.js`
- **Tipo**: integración
- **Qué hace**: valida comportamiento del mock SOAP SAT (vigente/no encontrado/errores de formato/EFOS).
- **Cómo está automatizado**: Jest + cliente `soap` + `startSATMockServer/stopSATMockServer`.
- **Qué problema resuelve / qué bug previene**: estabiliza pruebas fiscales sin depender de disponibilidad externa.
- **Requisitos asociados**: infraestructura de testing SAT.

### `verification-cfdi.e2e.test.js` -> `CFDI Verification service`
- **Archivo**: `TC3005B.501-Backend/tests/services/CDFI/verification-cfdi.e2e.test.js`
- **Tipo**: e2e
- **Qué hace**: valida flujo E2E de verificación CFDI con SAT mock y escenarios EFOS.
- **Cómo está automatizado**: Jest + Supertest + fixtures + mock server SAT + Prisma/PostgreSQL test DB (+ S3 mock vía LocalStack).
- **Qué problema resuelve / qué bug previene**: evita regresiones en validación fiscal extremo a extremo.
- **Requisitos asociados**: validación fiscal, EFOS.
- **Nota skip/todo**: contiene `it.skip` y comentario TODO en archivo.

## 3.8 Servicios BER / tipo de cambio

### `exchangeRate.e2e.test.js` -> `BER Banxico Exchange Rate Service E2E`
- **Archivo**: `TC3005B.501-Backend/tests/services/BER/exchangeRate.e2e.test.js`
- **Tipo**: e2e
- **Qué hace**: valida consulta de tipo de cambio, cache, fallback y errores de endpoint.
- **Cómo está automatizado**: Jest + Supertest + DB de prueba.
- **Qué problema resuelve / qué bug previene**: evita cotizaciones incorrectas o interrupciones de flujo por caída de proveedor.
- **Requisitos asociados**: NT-010 (referencia en test).

### `exchangeRate.test.js` -> `ExchangeRateService`
- **Archivo**: `TC3005B.501-Backend/tests/services/BER/exchangeRate.test.js`
- **Tipo**: unitario
- **Qué hace**: valida cache-hit, fallback Wise->DOF, conversiones y validación de fechas.
- **Cómo está automatizado**: Jest con spies/mocks sobre clientes externos.
- **Qué problema resuelve / qué bug previene**: evita conversiones erróneas y llamadas innecesarias.
- **Requisitos asociados**: BER / tipos de cambio.

### `bmx-api.test.js` -> `Banxico mock API contract`
- **Archivo**: `TC3005B.501-Backend/tests/services/BER/server/bmx-api.test.js`
- **Tipo**: integración
- **Qué hace**: valida contrato del mock de Banxico (auth, rate-limit, series, rangos, errores).
- **Cómo está automatizado**: Jest + Supertest contra mock Express.
- **Qué problema resuelve / qué bug previene**: garantiza que las pruebas BER se ejecuten con un proveedor simulado consistente.
- **Requisitos asociados**: infraestructura de pruebas BER.

## 3.9 Servicios de flujo, autorización y políticas

### `alertMessageResolver.test.js` -> `alertMessageResolver`
- **Archivo**: `TC3005B.501-Backend/tests/services/alertMessageResolver.test.js`
- **Tipo**: unitario
- **Qué hace**: verifica mapeo de mensajes de alerta por estado de solicitud.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita mensajes erróneos al usuario final.
- **Requisitos asociados**: UX de estados.

### `approvalSubstituteService.test.js` -> `createSubstitute | processStaleApprovals`
- **Archivo**: `TC3005B.501-Backend/tests/services/approvalSubstituteService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida sustitución de aprobadores y reasignación de pendientes.
- **Cómo está automatizado**: Jest con mocks de modelo/permisos.
- **Qué problema resuelve / qué bug previene**: evita bloqueos operativos por ausencia de aprobadores.
- **Requisitos asociados**: continuidad operativa.

### `approverInbox.test.js` -> `User.getTravelRequestsForApprover`
- **Archivo**: `TC3005B.501-Backend/tests/services/approverInbox.test.js`
- **Tipo**: integración
- **Qué hace**: valida filtros por estado, jerarquía y alcance por actor.
- **Cómo está automatizado**: Jest + prisma mock.
- **Qué problema resuelve / qué bug previene**: evita que aprobadores vean solicitudes incorrectas o incompletas.
- **Requisitos asociados**: flujo de autorización.

### `approverResolver.test.js` -> `resolveN1N2Approvers`
- **Archivo**: `TC3005B.501-Backend/tests/services/approverResolver.test.js`
- **Tipo**: unitario
- **Qué hace**: valida resolución base de aprobadores N1/N2.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita asignaciones nulas/inválidas de aprobadores.
- **Requisitos asociados**: workflow de aprobación.

### `authorizerService.test.js` -> `declineRequest | authorizeRequest`
- **Archivo**: `TC3005B.501-Backend/tests/services/authorizerService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida rechazo por comentario, escalamiento por monto y bloqueo por excepciones pendientes.
- **Cómo está automatizado**: Jest + mocks de servicios de soporte.
- **Qué problema resuelve / qué bug previene**: evita aprobaciones indebidas o saltos de nivel incorrectos.
- **Requisitos asociados**: políticas de autorización, M2-006.

### `employeeCategoryService.test.js` -> `employeeCategoryService`
- **Archivo**: `TC3005B.501-Backend/tests/services/employeeCategoryService.test.js`
- **Tipo**: integración
- **Qué hace**: valida CRUD, filtros por activos y colisiones de unicidad.
- **Cómo está automatizado**: Jest + prisma mock.
- **Qué problema resuelve / qué bug previene**: evita categorías inconsistentes por organización.
- **Requisitos asociados**: M2-006.

### `employeeHierarchyService.test.js` -> `employeeHierarchyService`
- **Archivo**: `TC3005B.501-Backend/tests/services/employeeHierarchyService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida cadena de aprobación, recursividad de subordinados y detección de ciclos.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita estructuras jerárquicas inválidas.
- **Requisitos asociados**: autorización jerárquica.

### `employeeSyncService.test.js` -> `syncEmployee`
- **Archivo**: `TC3005B.501-Backend/tests/services/employeeSyncService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida escenarios de alta/baja/cambio/reingreso.
- **Cómo está automatizado**: Jest + mocks de modelo.
- **Qué problema resuelve / qué bug previene**: evita desalineación entre sistema fuente y catálogo local de empleados.
- **Requisitos asociados**: sincronización administrativa.

### `expenseReportScope.test.js` -> `alcance por jerarquía`
- **Archivo**: `TC3005B.501-Backend/tests/services/expenseReportScope.test.js`
- **Tipo**: unitario
- **Qué hace**: valida qué roles ven reportes globales vs propios.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita exposición de gastos no autorizados.
- **Requisitos asociados**: control de acceso.

### `expenseReportService.test.js` -> `expenseReportService maps`
- **Archivo**: `TC3005B.501-Backend/tests/services/expenseReportService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida mapeos de tipo/estatus hacia categorías de reporte.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita reportes mal clasificados.
- **Requisitos asociados**: analítica de gastos.

### `flightSearchRoundTrip.test.js` -> `MockFlightProvider round trip`
- **Archivo**: `TC3005B.501-Backend/tests/services/flightSearchRoundTrip.test.js`
- **Tipo**: unitario
- **Qué hace**: valida marcado ida-vuelta cuando existe fecha de retorno.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita ofertas mal etiquetadas en viaje redondo.
- **Requisitos asociados**: módulo de agencia de viaje.

### `organizationService.test.js` -> `createOrganization | suspendOrganization | listOrganizations`
- **Archivo**: `TC3005B.501-Backend/tests/services/organizationService.test.js`
- **Tipo**: integración
- **Qué hace**: valida reglas de creación/suspensión/filtro de organizaciones.
- **Cómo está automatizado**: Jest + mocks prisma y bootstrap.
- **Qué problema resuelve / qué bug previene**: evita altas inválidas y suspensión accidental de organización ROOT.
- **Requisitos asociados**: administración multi-tenant.

### `permissionService.test.js` -> `loadEffectivePermissions | loadEffectivePermissionsForRole`
- **Archivo**: `TC3005B.501-Backend/tests/services/permissionService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida composición de permisos efectivos por usuario y rol.
- **Cómo está automatizado**: Jest + mock de `permissionModel`.
- **Qué problema resuelve / qué bug previene**: evita permisos faltantes o sobre-privilegios.
- **Requisitos asociados**: RBAC.

### `policyAlertService.test.js` -> `checkReceiptBeforeSubmit`
- **Archivo**: `TC3005B.501-Backend/tests/services/policyAlertService.test.js`
- **Tipo**: integración
- **Qué hace**: valida alertas de política, ausencia de política y uso de snapshot congelado.
- **Cómo está automatizado**: Jest + prisma mock.
- **Qué problema resuelve / qué bug previene**: evita re-evaluar retroactivamente políticas y notifica excedentes a tiempo.
- **Requisitos asociados**: RF-46 (referencia explícita en test).

### `policyExceptionService.test.js` -> `createException | decideException | listPendingForApprover`
- **Archivo**: `TC3005B.501-Backend/tests/services/policyExceptionService.test.js`
- **Tipo**: integración
- **Qué hace**: valida ciclo de vida de excepciones (pending/approved/rejected), trazabilidad e inbox de aprobador.
- **Cómo está automatizado**: Jest + mocks de Prisma/notificaciones.
- **Qué problema resuelve / qué bug previene**: evita decisiones de excepción sin autorización y estados huérfanos.
- **Requisitos asociados**: M2-006.

### `policyService.test.js` -> `createPolicy | updatePolicy | deactivatePolicy | snapshotPolicyForRequest`
- **Archivo**: `TC3005B.501-Backend/tests/services/policyService.test.js`
- **Tipo**: integración
- **Qué hace**: valida reglas de vigencia, solapamiento, caps y snapshot por solicitud.
- **Cómo está automatizado**: Jest + mocks de transacciones Prisma.
- **Qué problema resuelve / qué bug previene**: evita conflictos de políticas y retroactividad no deseada.
- **Requisitos asociados**: M2-006.

### `refundRuleEngine.test.js` -> `evaluateReceiptAgainstPolicy | findApplicablePolicy | summarize/build snapshot`
- **Archivo**: `TC3005B.501-Backend/tests/services/refundRuleEngine.test.js`
- **Tipo**: unitario
- **Qué hace**: valida motor de reglas de reembolso por unidad, matching y resumen.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita decisiones de reembolso incorrectas por unidad/alcance.
- **Requisitos asociados**: M2-006.

### `reimbursementTimeService.test.js` -> `get/setOrgTimeLimit | deadline | lockExpiredRequests`
- **Archivo**: `TC3005B.501-Backend/tests/services/reimbursementTimeService.test.js`
- **Tipo**: integración
- **Qué hace**: valida plazos de comprobación, gracia y bloqueo automático de solicitudes vencidas.
- **Cómo está automatizado**: Jest + prisma mock + transacciones.
- **Qué problema resuelve / qué bug previene**: evita comprobaciones tardías fuera de política.
- **Requisitos asociados**: M2-006.

### `escalationJob.test.js` -> `runEscalationJob`
- **Archivo**: `TC3005B.501-Backend/tests/services/scheduler/escalationJob.test.js`
- **Tipo**: integración
- **Qué hace**: valida escalamiento automático por tiempo y su idempotencia.
- **Cómo está automatizado**: Jest + mocks de prisma/notificaciones.
- **Qué problema resuelve / qué bug previene**: evita solicitudes atoradas en bandejas de aprobación.
- **Requisitos asociados**: SLA operativo de aprobación.

### `solicitudJourneyService.test.js` -> `approvalLevelsFromSnapshot | routeNeedsAgency | buildSolicitudJourney`
- **Archivo**: `TC3005B.501-Backend/tests/services/solicitudJourneyService.test.js`
- **Tipo**: unitario
- **Qué hace**: valida construcción del journey de solicitud y marcación de pasos.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita mostrar rutas de proceso incorrectas al usuario.
- **Requisitos asociados**: experiencia de seguimiento de solicitud.

### `userService.auth.test.js` -> `authenticateUser`
- **Archivo**: `TC3005B.501-Backend/tests/services/userService.auth.test.js`
- **Tipo**: unitario
- **Qué hace**: valida payload de autenticación con campos de empleado.
- **Cómo está automatizado**: Jest + mocks de `bcrypt` y `jsonwebtoken`.
- **Qué problema resuelve / qué bug previene**: evita token/respuesta incompleta para frontend.
- **Requisitos asociados**: autenticación.

### `workflowRulesEngine.test.js` -> `workflowRulesEngine`
- **Archivo**: `TC3005B.501-Backend/tests/services/workflowRulesEngine.test.js`
- **Tipo**: unitario
- **Qué hace**: valida bandas de importe, `skip_if_below`, manager steps y target role.
- **Cómo está automatizado**: Jest.
- **Qué problema resuelve / qué bug previene**: evita rutas de autorización equivocadas por reglas.
- **Requisitos asociados**: M2-004/M2-006.

## 3.10 Artefactos de soporte relevantes (backend)

| Tipo | Archivos | Uso |
|---|---|---|
| Utilidades | `tests/utils/createTestAuthToken.js`, `tests/utils/importXML.js`, `tests/utils/muteConsole.js` | apoyo a auth, carga de fixtures XML, limpieza de salida |
| Fixtures CFDI | `tests/services/CDFI/tax_invoices(CFDIs)/*.xml` | casos válidos y malformados para parser/validación |
| Mock SAT | `tests/services/CDFI/server/*` | WSDL, acuses y servidor mock SOAP |
| Mock BER/Banxico | `tests/services/BER/server/*` | API mock para pruebas de tipo de cambio |
| Fixtures storage | `tests/fixtures/storage/*` | PDFs/XML válidos e inválidos para carga de archivos |

---

## 4) Frontend — Tests

## 4.1 Configuración y ejecución

- **Runner unit/integration**: Vitest (`jsdom`, `tests/setup.ts`)
- **Testing de componentes**: React Testing Library + `@testing-library/user-event`
- **Mock de red**: MSW (`tests/frontend/mocks/server.ts`, `handlers.ts`)
- **E2E**: Cypress (`cypress/e2e/*.cy.ts`)

## 4.2 Utilidades y lógica de negocio

### `expenseSettlement.test.ts` -> `expenseSettlement`
- **Archivo**: `TC3005B.501-Frontend/tests/utils/expenseSettlement.test.ts`
- **Tipo**: unitario
- **Qué hace**: valida cálculo de saldo/reembolso considerando anticipo e impuestos.
- **Cómo está automatizado**: Vitest, pruebas de función pura.
- **Qué problema resuelve / qué bug previene**: evita mostrar saldo erróneo al solicitante.
- **Requisitos asociados**: módulo de comprobación/reembolso.
- **Nota importante**: por configuración actual (`vitest.config.ts`), este archivo queda fuera de `include` (`tests/frontend/**`) y puede no ejecutarse en `bun run test`.

### `travelRequestAgency.test.ts` -> `travelRequestAgency`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/utils/travelRequestAgency.test.ts`
- **Tipo**: unitario
- **Qué hace**: valida utilidades para IATA, flags de agencia y defaults de búsqueda de vuelo/hotel.
- **Cómo está automatizado**: Vitest.
- **Qué problema resuelve / qué bug previene**: evita parámetros de búsqueda inconsistentes.
- **Requisitos asociados**: flujo de agencia de viajes.

### `uploadOnboarding.test.ts` -> `uploadOnboarding`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/utils/uploadOnboarding.test.ts`
- **Tipo**: unitario
- **Qué hace**: valida la lógica de utilidades de carga de archivos durante el flujo de onboarding de organización.
- **Cómo está automatizado**: Vitest.
- **Qué problema resuelve / qué bug previene**: evita errores de carga silenciosos durante el proceso de alta de nueva organización.
- **Requisitos asociados**: módulo de onboarding.

## 4.3 Componentes UI base

### `Button.test.tsx` -> `Button`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/Button.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida render, variantes, tamaños, click, disabled y attrs nativos.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita degradaciones visuales/funcionales de botones críticos.
- **Requisitos asociados**: N/A.

### `InputField.test.tsx` -> `InputField`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/InputField.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida label/required/error/helper/disabled y accesibilidad.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita errores de captura y accesibilidad.
- **Requisitos asociados**: N/A.

### `Select.test.tsx` -> `Select`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/Select.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida búsqueda, teclado, placeholder, disabled y clic fuera.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita selección incorrecta y problemas de UX en filtros/formularios.
- **Requisitos asociados**: N/A.

### `Modal.test.tsx` -> `Modal`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/Modal.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida apertura/cierre, escape/overlay, botones y estilos de tipo.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita confirmar/cancelar acciones con comportamiento inconsistente.
- **Requisitos asociados**: N/A.

### `Toast.test.tsx` -> `Toast`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/Toast.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida render y autocierre por timeout.
- **Cómo está automatizado**: Vitest + timers falsos.
- **Qué problema resuelve / qué bug previene**: evita notificaciones persistentes o fugaces de forma errática.
- **Requisitos asociados**: N/A.

### `ProgressBar.test.tsx` -> `ProgressBar`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/ProgressBar.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida ARIA, cálculo de porcentaje, clamp y estilos.
- **Cómo está automatizado**: Vitest + RTL.
- **Qué problema resuelve / qué bug previene**: evita métricas de progreso engañosas.
- **Requisitos asociados**: N/A.

### `FileDropZone.test.tsx` -> `FileDropZone`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/FileDropZone.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida drop, clasificación XML/PDF y errores por tipo inválido.
- **Cómo está automatizado**: Vitest + RTL, `vi.mock("react-dropzone")`.
- **Qué problema resuelve / qué bug previene**: evita carga de documentos no permitidos desde UI.
- **Requisitos asociados**: carga de comprobantes.

### `DataTable.test.tsx` -> `DataTable`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/DataTable.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida sorting, paginación, render de filas y rutas de acción.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita ordenamientos y navegación errónea en listados críticos.
- **Requisitos asociados**: N/A.

## 4.4 Componentes de negocio y módulos funcionales

### `CfdiSatBadge.test.tsx` -> `CfdiSatBadge`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/CfdiSatBadge.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida estados SAT (`Vigente`, `Cancelado`, `No encontrado`), skeleton, fallback y retry.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita mostrar estatus fiscal incorrecto o UI sin recuperación.
- **Requisitos asociados**: validación CFDI/SAT.

### `XmlExpenseForm.test.tsx` -> `XmlExpenseForm`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/XmlExpenseForm.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida parseo XML, autofill de campos y validación de formulario.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita registros de gasto incompletos o mal parseados.
- **Requisitos asociados**: carga de comprobantes.

### `UploadReceiptFiles.test.tsx` -> `UploadReceiptFiles`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/UploadReceiptFiles.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida upload/delete de comprobantes y manejo de error.
- **Cómo está automatizado**: Vitest + RTL + MSW.
- **Qué problema resuelve / qué bug previene**: evita reemplazos fallidos de comprobantes y estados inconsistentes.
- **Requisitos asociados**: flujo de comprobación.

### `ResumenTramos.test.tsx` -> `ResumenTramos`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/ResumenTramos.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida resumen de tramos, total MXN, expand/collapse, estados vacío/error.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita reportes visuales erróneos de gasto por tramo.
- **Requisitos asociados**: reporte de comprobaciones.

### `ApprovalsInbox.test.tsx` -> `ApprovalsInbox`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/ApprovalsInbox.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida filtros (tipo, monto, fecha), vacíos, limpieza y banner read-only.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita pérdida de productividad por filtros incorrectos en aprobaciones.
- **Requisitos asociados**: flujo de autorización.

### `AuthRequestsList.test.tsx` -> `AuthRequestsList`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/AuthRequestsList.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida encabezados, paginación, links y fallback de carga.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita navegación errática en bandeja de solicitudes.
- **Requisitos asociados**: flujo de autorización.

### `RolesAdmin.test.tsx` -> `RolesAdmin`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/RolesAdmin.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida crear/editar/eliminar roles, toggles de permisos y guardrails de último admin.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita romper el esquema de seguridad al administrar roles.
- **Requisitos asociados**: sistema de permisos.

### `SimuladorWorkflow.test.tsx` -> `SimuladorWorkflow`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/SimuladorWorkflow.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida simulación remota/local y rutas de aprobación resultantes.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita simulaciones de flujo engañosas para operación.
- **Requisitos asociados**: reglas de workflow.

### `PolicyAlert.test.tsx` -> `PolicyAlert`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/PolicyAlert.test.tsx`
- **Tipo**: unitario
- **Qué hace**: valida render condicional de alerta y callback de justificación.
- **Cómo está automatizado**: Vitest + RTL + user-event.
- **Qué problema resuelve / qué bug previene**: evita omitir alertas cuando se rebasa política.
- **Requisitos asociados**: RF-44 (alerta proactiva).

### `PolicyExceptionModal.test.tsx` -> `PolicyExceptionModal`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/PolicyExceptionModal.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida mínimo de justificación y submit exitoso de excepción.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita solicitudes de excepción sin fundamento suficiente.
- **Requisitos asociados**: M2-006.

### `RefundDashboard.test.tsx` -> `RefundDashboard`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/RefundDashboard.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida carga con `initialData`, banner deadline, vacíos y errores API.
- **Cómo está automatizado**: Vitest + RTL + MSW.
- **Qué problema resuelve / qué bug previene**: evita tableros inconsistentes de reembolso.
- **Requisitos asociados**: M2-006.

### `RefundTimeLimitConfig.test.tsx` -> `RefundTimeLimitConfig`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/RefundTimeLimitConfig.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida lectura/actualización de límites de tiempo.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita configuración operativa incorrecta de plazos.
- **Requisitos asociados**: M2-006.

### `CustomImportRoleModal.test.tsx` -> `CustomImportRoleModal`
- **Archivo**: `TC3005B.501-Frontend/tests/frontend/components/CustomImportRoleModal.test.tsx`
- **Tipo**: integración
- **Qué hace**: valida el modal de importación personalizada de roles, incluyendo selección, confirmación y manejo de errores.
- **Cómo está automatizado**: Vitest + RTL + user-event + MSW.
- **Qué problema resuelve / qué bug previene**: evita importaciones de roles incorrectas o incompletas durante la administración de organización.
- **Requisitos asociados**: administración de roles.

## 4.5 End-to-end (Cypress)

### `create-request.cy.ts` -> `Creación de solicitud`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/create-request.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida envío exitoso de solicitud de viaje.
- **Cómo está automatizado**: Cypress con login/logout por comando custom.
- **Qué problema resuelve / qué bug previene**: evita ruptura del flujo principal de alta de solicitudes.
- **Requisitos asociados**: flujo solicitante.

### `draft-request.cy.ts` -> `Gestión de borradores`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/draft-request.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida guardar, editar y eliminar borradores.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita pérdida de trabajo de usuario al preparar solicitudes.
- **Requisitos asociados**: UX de borradores.

### `edit-travel-request.cy.ts` -> `Edit Travel Request`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/edit-travel-request.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida edición y errores por campos obligatorios.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita edición inválida de solicitudes.
- **Requisitos asociados**: flujo solicitante.

### `update-request.cy.ts` -> `Edición de solicitud existente`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/update-request.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida actualización de solicitud en estado editable.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita que cambios del solicitante no persistan.
- **Requisitos asociados**: flujo solicitante.

### `request-details.cy.ts` -> `Visualización de detalles`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/request-details.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida navegación a detalle desde listados.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita links rotos o detalle inaccesible.
- **Requisitos asociados**: flujo solicitante.

### `request-state-change.cy.ts` -> `Primera -> Segunda revisión`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/request-state-change.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida transición de estado por autorización N2.
- **Cómo está automatizado**: Cypress con búsqueda paginada de solicitud.
- **Qué problema resuelve / qué bug previene**: evita estados de workflow atascados o mal transicionados.
- **Requisitos asociados**: autorización por niveles.

### `cancel-request.cy.ts` -> `Cancelación por solicitante`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/cancel-request.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida cancelación permitida/prohibida según estado.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita cancelaciones fuera de política.
- **Requisitos asociados**: reglas de estado.

### `date-validation.cy.ts` -> `Validación de fechas`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/date-validation.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida obligatoriedad y orden lógico de fechas.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita solicitudes con rango temporal inválido.
- **Requisitos asociados**: validaciones de formulario.

### `empty-fields-error.cy.ts` -> `Campos obligatorios vacíos`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/empty-fields-error.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida mensajes de error por campos obligatorios omitidos.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita envíos incompletos sin feedback claro.
- **Requisitos asociados**: validaciones UX.

### `document-validation.cy.ts` -> `Validación al subir comprobantes`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/document-validation.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida aceptación/rechazo de archivos al subir comprobantes.
- **Cómo está automatizado**: Cypress + `cypress-file-upload` + fixtures.
- **Qué problema resuelve / qué bug previene**: evita subir formatos no permitidos desde cliente.
- **Requisitos asociados**: carga documental.
- **Nota**: se observó posible desalineación de fixture inválido; **requiere clarificación**.

### `comments-section.cy.ts` -> `Request Comments Section`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/comments-section.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida render, envío, errores, scroll y stream SSE de comentarios.
- **Cómo está automatizado**: Cypress + `cy.intercept`.
- **Qué problema resuelve / qué bug previene**: evita fallas de comunicación entre solicitante/aprobador en tiempo real.
- **Requisitos asociados**: colaboración en solicitudes.

### `permissions.cy.ts` -> `Granular permission system`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/permissions.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida resolución de permisos por rol, guardas auth, CRUD de permisos/grupos y grants directos.
- **Cómo está automatizado**: Cypress + comandos API (`apiLogin`, `apiAs`) con CSRF/Bearer.
- **Qué problema resuelve / qué bug previene**: evita escalaciones indebidas de privilegios y regresiones RBAC.
- **Requisitos asociados**: seguridad/autorización.

### `refund-rules.cy.ts` -> `M2-006 políticas/categorías/plazos + RF-44`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/refund-rules.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida CRUD admin de políticas/categorías/plazos, alerta proactiva y permisos de acceso.
- **Cómo está automatizado**: Cypress + intercepts para preview + login por rol.
- **Qué problema resuelve / qué bug previene**: evita que nuevas reglas de reembolso rompan operación o seguridad.
- **Requisitos asociados**: M2-006, RF-44.

### `role-navigation.cy.ts` -> `Rutas restringidas por rol`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/role-navigation.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida denegación de rutas a roles no autorizados y redirección a login sin sesión.
- **Cómo está automatizado**: Cypress.
- **Qué problema resuelve / qué bug previene**: evita exposición de pantallas restringidas.
- **Requisitos asociados**: control de acceso.

### `test-login-command.cy.ts` -> `Comandos login/logout`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/test-login-command.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida existencia/uso básico de comandos custom de sesión.
- **Cómo está automatizado**: Cypress + `cypress/support/commands.ts`.
- **Qué problema resuelve / qué bug previene**: evita suites inestables por comandos rotos de autenticación.
- **Requisitos asociados**: infraestructura de testing E2E.

### `ti-001-flujo-completo.cy.ts` -> `TI-001 flujo completo`
- **Archivo**: `TC3005B.501-Frontend/cypress/e2e/ti-001-flujo-completo.cy.ts`
- **Tipo**: e2e
- **Qué hace**: valida el flujo completo de solicitud de viaje extremo a extremo (TI-001), desde la creación hasta el cierre del proceso.
- **Cómo está automatizado**: Cypress con comandos de login por rol.
- **Qué problema resuelve / qué bug previene**: evita regresiones en el recorrido crítico de negocio de inicio a fin.
- **Requisitos asociados**: TI-001.

## 4.6 Soporte de pruebas relevante (frontend)

| Tipo | Archivos | Uso |
|---|---|---|
| Setup global | `tests/setup.ts` | `jest-dom`, limpieza DOM, ciclo de vida MSW |
| Mocks API | `tests/frontend/mocks/handlers.ts`, `tests/frontend/mocks/server.ts` | respuestas controladas para integración de componentes |
| Cypress support | `cypress/support/commands.ts`, `cypress/support/e2e.ts` | comandos de login/logout y login API |

---

## 5) Gaps y recomendaciones

## Hallazgos de cobertura

1. **Frontend CI no ejecuta pruebas**: el workflow actual corre typecheck/build/audit, pero no Vitest ni Cypress.
2. **Archivo fuera del include de Vitest**: `tests/utils/expenseSettlement.test.ts` no entra al patrón `tests/frontend/**/*.test.{ts,tsx}`.
3. **Evidencia de deuda en backend CFDI/comentarios**: existen `it.skip`/TODO en `requestCommentController.test.js` y `verification-cfdi.e2e.test.js`.
4. **No hay consolidado de cobertura versionado**: no se encontró `coverage-summary.json` en árbol para reporte global reproducible.
5. **Hooks frontend**: no se detectaron tests dedicados a hooks como categoría separada; cobertura está concentrada en componentes/utilidades.

## Recomendaciones priorizadas (siguientes sprints)

| Prioridad | Recomendación | Impacto esperado |
|---|---|---|
| Alta | Agregar job de `bun run test` en frontend CI y publicar artifacts de cobertura | Reduce regresiones UI antes de merge |
| Alta | Ajustar `vitest.config.ts` para incluir `tests/utils/**/*.test.ts` (o mover archivo) | Evita falso positivo de cobertura |
| Alta | Resolver y reactivar tests `skip` en backend | Cierra deuda técnica en flujos sensibles |
| Media | Definir umbral mínimo de cobertura backend global por carpeta crítica | Mejora gobernanza de calidad |
| Media | Agregar smoke E2E frontend en CI (subset estable) | Cobertura de journeys críticos en PR |
| Media | Estandarizar trazabilidad RF/US en nombres de `describe` | Facilita auditoría con SRS |

---

## 6) Apéndice

## 6.1 Comandos útiles de prueba

### Backend

```bash
# Ejecutar unit + integración (sin e2e)
bun run test

# Modo watch
bun run test:watch

# Solo e2e backend
bun run test:e2e

# Todos los tests backend
bun run test:all

# Filtrar por archivo
bunx jest tests/services/policyService.test.js

# Filtrar por nombre de caso
bunx jest -t "snapshotPolicyForRequest"
```

### Frontend

```bash
# Unit/integration
bun run test

# Watch
bun run test:watch

# Coverage
bun run test:coverage

# Ejecutar un archivo específico Vitest
bunx vitest run tests/frontend/components/RolesAdmin.test.tsx

# Cypress interactivo / headless
bunx cypress open
bunx cypress run

# Cypress por spec
bunx cypress run --spec "cypress/e2e/refund-rules.cy.ts"
```

## 6.2 Cómo agregar un nuevo test (convenciones del proyecto)

1. **Ubicar capa correcta**
   - Backend unit/integration: `tests/services|controllers|middleware/...`
   - Backend e2e: `tests/**/*.e2e.test.js`
   - Frontend unit/integration: `tests/frontend/**`
   - Frontend e2e: `cypress/e2e/**`

2. **Nombrar archivo**
   - `featureName.test.js|ts|tsx`
   - e2e frontend: `feature-name.cy.ts`

3. **Estructurar caso**
   - `describe("módulo o feature")`
   - `it("escenario de negocio esperado")`
   - Incluir un caso feliz + al menos un caso de error/permiso.

4. **Usar mocks/fixtures apropiados**
   - Backend: mocks de servicios externos, fixtures XML/JSON, seeds de test.
   - Frontend: MSW para API, fixtures Cypress para archivos y payloads.

5. **Evitar ambigüedad funcional**
   - Nombre de caso debe describir valor de negocio (no solo detalle técnico).
   - Si el comportamiento no es claro, documentar en comentario `requiere clarificación`.

6. **Verificar localmente antes de PR**
   - Backend: `bun run test` y, si toca flujo completo, `bun run test:e2e`.
   - Frontend: `bun run test` y e2e relevante (`bunx cypress run --spec ...`).

---

## Nota final de trazabilidad

Este documento prioriza fidelidad técnica frente a inferencias. Donde no existe referencia explícita a US/RF/RNF en el código de test, se dejó la asociación a nivel de módulo o se marcó como necesidad de trazabilidad adicional para el SRS.
