# M2-006 — Casos de prueba manuales (M2-QA1 / M2-QA2)

**Card:** M2-006 — Motor de reglas de reembolso
**Sprint:** S-003
**Responsables:** Mariano Carretero (dev) · Eder Cantero (QA) · Erick Morales (Postman)
**Cobertura:** US-06 (RF-37/38/39) y US-12 (RF-42..46)

> Pre-requisito: `bun run docker:dev` + `bun run dummy_db` (corre el seed con `seedRefundDefaults`).
> Frontend: `bun run dev` (Astro). Usuarios Cypress en `.env`.

---

## RF-37 · Plazo configurable (default 14 días)

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-01** | Login Administrador → `/admin/refund-time-limits` → cambiar `daysAfterTrip` a 7 → Guardar. Recargar. | Toast "Configuración actualizada". Al recargar el valor persiste en 7. |
| **M2-006-02** | Repetir el paso anterior con `daysAfterTrip=0`. | Toast/error de validación 400. No se persiste. |

## RF-38 · Aprobador revisa el reembolso

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-03** | Login Solicitante → crear solicitud y subir comprobantes dentro del plazo → enviar a validación. Login N1 → `/autorizaciones` → revisar y aprobar/rechazar. | El flujo de aprobación M2-005 sigue funcionando sin regresión y la solicitud cambia de estado correctamente. |

## RF-39 · Bloqueo de comprobaciones fuera del plazo

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-04** | Forzar `Request.tripEndDate = today − 20 días` (vía Prisma Studio o seed) y `daysAfterTrip = 14`. Login Solicitante → intentar subir comprobante en `/subir-comprobante/{id}`. | El backend retorna `403` con mensaje `"Plazo de reembolso vencido (14 días desde fin de viaje)..."`. El front muestra alerta. |
| **M2-006-05** | Ejecutar manualmente el cron `refundDeadlineJob` (`SCHEDULER_ENABLED=true` y esperar la próxima corrida programada, o invocar `runRefundDeadlineJob()` desde un script). | La solicitud queda en `requestStatusId=8 (Finalizado)` y se inserta historial `RECHAZADO` con comentario "Cierre automático por plazo de reembolso vencido". |

## RF-42 / RF-43 · Configuración de políticas y topes

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-06** | Login Administrador → `/admin/expense-policies` → crear política nacional con cap `Hospedaje 2500/per_night`, `Comida 800/per_day`, `Vuelo 8000/per_trip`. | La política aparece en la lista; sus 3 caps son visibles al editar. |
| **M2-006-07** | Crear política con `validFrom > validTo`. | Validación 400 inline antes de enviar; backend rechaza también. |

## RF-44 · Alerta proactiva al solicitante

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-08** | Login Solicitante → `/subir-comprobante/{id}` → seleccionar `Concepto = Hospedaje`, `Monto = 2000` MXN. Subir CFDI. | No hay banner de alerta. El comprobante se crea con `refund=true`. |
| **M2-006-09** | Mismo flujo con `Monto = 3500` MXN. | Aparece banner amarillo "Excede política" + botón "Justificar". El submit está bloqueado hasta que el usuario justifique. |

## RF-45 · Excepción autorizada con justificación

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-10** | Después de M2-006-09, click "Justificar y enviar de todos modos" → escribir "Único hotel disponible cerca del congreso esta semana" → Enviar justificación. | Se crea `PolicyException` PENDING; toast informa que se justificó. Reintentar Submit registra el comprobante con `refund=false` (queda pendiente de decisión del aprobador). |
| **M2-006-11** | Login N1 (aprobador designado) → `/autorizaciones` → ver sección "Excepciones de política pendientes" → Aprobar la excepción con nota. | El receipt queda con `refund=true`. Se inserta historial `APROBADO` con referencia a la excepción. El solicitante recibe notificación in-app. |
| **M2-006-12** | Repetir M2-006-11 con login N2 (que NO está designado en `workflowPreSnapshot.n1UserId`). | Backend retorna `403`. |
| **M2-006-13** | Aprobador intenta aprobar la solicitud completa (`POST /api/solicitudes/:id/aprobar`) cuando todavía hay una `PolicyException` PENDING. | Backend retorna `409` con mensaje "Resuelva las excepciones de política pendientes antes de aprobar la solicitud." |

## RF-46 · Vigencia de políticas (no retroactividad)

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-14** | Login Administrador → editar la política y poner `validTo = ayer`. Crear una nueva solicitud y revisar `Request.policyEvaluationSnapshot`. | La solicitud nueva NO recibe la política expirada (busca catch-all o queda sin política). |
| **M2-006-15** | Modificar el `dailyPerDiem` de una política activa que ya fue aplicada a una solicitud existente. | `Request.policyEvaluationSnapshot` de la solicitud previa conserva los valores originales. |

## RF-35 (absorbido) · Escalamiento automático 48h

| TC | Pasos | Resultado esperado |
|----|-------|--------------------|
| **M2-006-16** | Forzar una solicitud en `requestStatusId=2` con `lastModDate = now - 49h` y snapshot `levels:[1,2]`. Ejecutar `escalationJob`. | La solicitud pasa a `requestStatusId=3`, se inserta historial `ESCALADO`, se notifica al N2. |

---

## Cobertura automatizada complementaria

| Tipo | Archivo | Cubre |
|------|---------|-------|
| Unit Jest | `tests/services/refundRuleEngine.test.js` | Motor puro (caps, vigencia, prioridad) |
| Unit Jest | `tests/services/policyService.test.js` | CRUD + overlap + snapshot |
| Unit Jest | `tests/services/policyExceptionService.test.js` | Crear/decidir excepciones, permisos |
| Unit Jest | `tests/services/reimbursementTimeService.test.js` | Plazo, deadline, lock |
| Unit Jest | `tests/services/policyAlertService.test.js` | Preview pre-submit |
| Unit Jest | `tests/services/scheduler/escalationJob.test.js` | Escalamiento 48h |
| E2E Jest+supertest | `tests/routes/refundRules.e2e.test.js` | RBAC, flow APROBADO/REJECTED, inbox |
| Unit Vitest+RTL | `tests/frontend/components/PolicyAlert.test.tsx` | Banner RF-44 |
| Unit Vitest+RTL | `tests/frontend/components/PolicyExceptionModal.test.tsx` | Modal RF-45 |
| Unit Vitest+RTL | `tests/frontend/components/RefundDashboard.test.tsx` | Panel /reembolso |
| Unit Vitest+RTL | `tests/frontend/components/RefundTimeLimitConfig.test.tsx` | Config RF-37 |
| E2E Cypress | `cypress/e2e/refund-rules.cy.ts` | Admin + RF-44 + permisos |

---

## Postman (NT-016)

A coordinar con Erick Morales: agregar al collection `coco_postman` los endpoints nuevos:
- `POST /api/policies` + `GET /api/policies/:id` + `POST /api/policies/preview`
- `GET/POST/PUT/DELETE /api/employee-categories`
- `GET/PUT /api/refunds/time-limit`
- `POST /api/refunds/exceptions` + `POST /api/refunds/exceptions/:id/decide`
- `GET /api/refunds/by-user/:userId` + `GET /api/refunds/request/:requestId/summary`
- `GET /api/solicitudes/inbox`
