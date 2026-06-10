# Lista de Procesos

> **Versión:** 2.0
> **Fecha:** 2026-06-10
> **Responsables:** Equipo CoCo Consulting 2
> **Estado:** Actualizada a PostgreSQL / Prisma — sin triggers MariaDB
> **Base:** CSV legado (41 procesos) + 30 archivos de rutas (170+ endpoints)

---

## Convenciones

| Columna | Descripción |
|---------|-------------|
| **ID** | Identificador del proceso (`P01`–`Pnn`) |
| **Dominio** | Área funcional o módulo |
| **Proceso** | Nombre descriptivo de la operación |
| **Endpoint** | Ruta HTTP relativa a `/api` (o mecanismo interno) |
| **Método** | `GET` · `POST` · `PUT` · `PATCH` · `DELETE` · `SSE` · Evento · Cron |
| **Tipo** | `Core` (operación de negocio) · `Soporte` (consulta/lectura) · `Gestión` (administración) |
| **Actor(es)** | Rol(es) que invocan el proceso |
| **Trigger / Mecanismo** | Evento o acción que dispara el proceso |

---

## Tabla maestra de procesos

### Auth (P01–P02)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P01 | Auth | Login | `POST /api/user/login` | POST | Core | Todos | Usuario envía credenciales |
| P02 | Auth | Logout | `GET /api/user/logout` | GET | Core | Todos | Usuario cierra sesión |

### Usuario (P03–P06)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P03 | Usuario | Obtener datos usuario | `GET /api/user/get-user-data/:user_id` | GET | Soporte | Todos | Carga de perfil |
| P04 | Usuario | Obtener solicitud por ID | `GET /api/user/get-travel-request/:request_id` | GET | Soporte | Todos | Consulta detalle |
| P05 | Usuario | Listar solicitudes por depto/status | `GET /api/user/get-travel-requests/:dept_id/:status_id/:n?` | GET | Soporte | Todos | Dashboard (deprecated) |
| P06 | Usuario | Obtener wallet | `GET /api/user/get-user-wallet/:user_id?` | GET | Soporte | Todos | Ver saldo |

### Solicitudes (P07–P16)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P07 | Solicitudes | Obtener solicitante por ID | `GET /api/applicant/:id` | GET | Soporte | Solicitante, N1, N2 | Consulta |
| P08 | Solicitudes | Obtener centro de costo | `GET /api/applicant/get-cc/:user_id` | GET | Soporte | Solicitante, N1, N2 | Crear solicitud |
| P09 | Solicitudes | Crear solicitud de viaje | `POST /api/applicant/create-travel-request/:user_id` | POST | Core | Solicitante, N1, N2 | Formulario solicitud |
| P10 | Solicitudes | Editar solicitud de viaje | `PUT /api/applicant/edit-travel-request/:user_id` | PUT | Core | Solicitante, N1, N2 | Edición solicitud |
| P11 | Solicitudes | Cancelar solicitud | `PUT /api/applicant/cancel-travel-request/:request_id` | PUT | Core | Solicitante, N1, N2 | Botón cancelar |
| P12 | Solicitudes | Crear borrador | `POST /api/applicant/create-draft-travel-request/:user_id` | POST | Core | Solicitante, N1, N2 | Guardar borrador |
| P13 | Solicitudes | Confirmar borrador | `PUT /api/applicant/confirm-draft-travel-request/:user_id/:request_id` | PUT | Core | Solicitante, N1, N2 | Confirmar draft |
| P14 | Solicitudes | Obtener solicitudes activas | `GET /api/applicant/get-user-requests/:user_id` | GET | Soporte | Solicitante, N1, N2, Agencia | Dashboard |
| P15 | Solicitudes | Obtener solicitud específica | `GET /api/applicant/get-user-request/:user_id` | GET | Soporte | Solicitante, N1, N2, Agencia | Detalle |
| P16 | Solicitudes | Obtener solicitudes completadas | `GET /api/applicant/get-completed-requests/:user_id` | GET | Soporte | Solicitante, N1, N2 | Historial |

### Gastos (P17–P19)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P17 | Gastos | Crear comprobantes de gasto | `POST /api/applicant/create-expense-validation` | POST | Core | Solicitante, N1, N2 | Formulario gastos |
| P18 | Gastos | Enviar comprobantes para validación | `PUT /api/applicant/send-expense-validation/:request_id` | PUT | Core | Solicitante, N1, N2 | Botón enviar |
| P19 | Gastos | Eliminar recibo | `DELETE /api/applicant/delete-receipt/:receipt_id` | DELETE | Soporte | Solicitante, N1, N2 | Botón eliminar |

### Aprobación (P20–P22)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P20 | Aprobación | Obtener alertas | `GET /api/authorizer/get-alerts/:dept_id/:status_id/:n` | GET | Core | N1, N2 | Dashboard autorizador |
| P21 | Aprobación | Autorizar solicitud | `PUT /api/authorizer/authorize-travel-request/:request_id/:user_id` | PUT | Core | N1, N2 | Botón aprobar |
| P22 | Aprobación | Rechazar solicitud | `PUT /api/authorizer/decline-travel-request/:request_id/:user_id` | PUT | Core | N1, N2 | Botón rechazar |

### Viaje (P23–P27)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P23 | Viaje | Atender solicitud (Agencia) | `PUT /api/travel-agent/attend-travel-request/:request_id` | PUT | Core | Agencia | Botón atender |
| P24 | Viaje | Atender solicitud (CxP) | `PUT /api/accounts-payable/attend-travel-request/:request_id` | PUT | Core | CxP | Cotizar viaje |
| P25 | Viaje | Validar recibos (batch) | `PUT /api/accounts-payable/validate-receipts/:request_id` | PUT | Core | CxP | Validar todos |
| P26 | Viaje | Validar recibo individual | `PUT /api/accounts-payable/validate-receipt/:receipt_id` | PUT | Core | CxP | Aprobar/rechazar |
| P27 | Viaje | Obtener validaciones de gastos | `GET /api/accounts-payable/get-expense-validations/:request_id` | GET | Soporte | CxP, Solicitante, N1, N2 | Ver recibos |

### Archivos (P28–P30)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P28 | Archivos | Subir archivos recibo (PDF+XML) | `POST /api/files/upload-receipt-files/:receipt_id` | POST | Core | Todos | Upload archivos |
| P29 | Archivos | Descargar archivo recibo | `GET /api/files/receipt-file/*` | GET | Soporte | Todos | Download archivo |
| P30 | Archivos | Obtener metadata archivos | `GET /api/files/receipt-files/:receipt_id` | GET | Soporte | Todos | Listar archivos |

### Admin (P31–P35)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P31 | Admin | Listar usuarios | `GET /api/admin/get-user-list` | GET | Gestión | Admin | Panel admin |
| P32 | Admin | Crear usuario | `POST /api/admin/create-user` | POST | Gestión | Admin | Formulario |
| P33 | Admin | Crear usuarios masivo (CSV) | `POST /api/admin/create-multiple-users` | POST | Gestión | Admin | Upload CSV |
| P34 | Admin | Actualizar usuario | `PUT /api/admin/update-user/:user_id` | PUT | Gestión | Admin | Edición |
| P35 | Admin | Desactivar usuario | `PUT /api/admin/delete-user/:user_id` | PUT | Gestión | Admin | Soft delete |

### Triggers Prisma (P36–P40) — antes MariaDB, ahora `Prisma $extends`

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P36 | Prisma Extension | Desactivar solicitud al cancelar/rechazar | — | Evento | Soporte | Sistema | `Prisma $extends (triggerExtension)` en `prisma/middleware.js` — `request.update` set `active=false` cuando status = 9 o 10 |
| P37 | Prisma Extension | Crear alerta al crear solicitud | — | Evento | Soporte | Sistema | Service layer en `models/applicantModel.js` — transaction-local al crear solicitud |
| P38 | Prisma Extension | Actualizar/eliminar alerta tras cambio de solicitud | — | Evento | Soporte | Sistema | `Prisma $extends (triggerExtension)` en `prisma/middleware.js` — auto-crea/actualiza/elimina alertas según status |
| P39 | Prisma Extension | Descontar wallet al imponer fee | — | Evento | Soporte | Sistema | `Prisma $extends (triggerExtension)` en `prisma/middleware.js` — `wallet -= imposed_fee` |
| P40 | Prisma Extension | Acreditar wallet al aprobar recibo | — | Evento | Soporte | Sistema | `Prisma $extends (triggerExtension)` en `prisma/middleware.js` — `wallet += receipt.amount` |

### Notificaciones (P41)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P41 | Notificaciones | Notificación multicanal (email + Web Push + in-app) | — | Evento | Soporte | Sistema | `workflowNotificationService.js` — dispatchToUser() envía por Email + Web Push + In-App según preferencias del usuario |

---

### Solicitud Workflow (P42–P45)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P42 | Solicitud Workflow | Aprobar solicitud (workflow) | `POST /api/solicitud-workflow/:id/aprobar` | POST | Core | N1, N2 | Botón aprobar (motor de reglas) |
| P43 | Solicitud Workflow | Rechazar solicitud (workflow) | `POST /api/solicitud-workflow/:id/rechazar` | POST | Core | N1, N2 | Botón rechazar (motor de reglas) |
| P44 | Solicitud Workflow | Reasignar solicitud | `POST /api/solicitud-workflow/:id/reasignar` | POST | Core | N1, N2 | Reasignación manual |
| P45 | Solicitud Workflow | Historial de solicitud | `GET /api/solicitud-workflow/:id/historial` | GET | Soporte | Todos | Consulta historial de cambios |

### Approval Substitutes (P46–P48)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P46 | Approval Substitutes | Listar sustitutos de aprobación | `GET /api/approval-substitutes` | GET | Soporte | N1, N2, Admin | Consulta sustitutos |
| P47 | Approval Substitutes | Crear sustituto de aprobación | `POST /api/approval-substitutes` | POST | Core | N1, N2, Admin | Asignar suplente temporal |
| P48 | Approval Substitutes | Eliminar sustituto de aprobación | `DELETE /api/approval-substitutes/:id` | DELETE | Core | N1, N2, Admin | Revocar suplente |

### Inbox (P49)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P49 | Inbox | Bandeja de aprobaciones | `GET /api/inbox/inbox` | GET | Soporte | N1, N2 | Dashboard aprobaciones pendientes |

### Workflow Rules (P50–P58)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P50 | Workflow Rules | Listar reglas de workflow | `GET /api/workflow-rules` | GET | Gestión | Admin | Consulta reglas |
| P51 | Workflow Rules | Crear regla de workflow | `POST /api/workflow-rules` | POST | Gestión | Admin | Formulario regla |
| P52 | Workflow Rules | Actualizar regla de workflow | `PUT /api/workflow-rules/:id` | PUT | Gestión | Admin | Edición regla |
| P53 | Workflow Rules | Toggle regla de workflow | `PATCH /api/workflow-rules/:id/toggle` | PATCH | Gestión | Admin | Activar/desactivar regla |
| P54 | Workflow Rules | Preview de reglas | `POST /api/workflow-rules/preview` | POST | Gestión | Admin | Previsualizar efecto |
| P55 | Workflow Rules | Catálogo: departamentos | `GET /api/workflow-rules/departments` | GET | Soporte | Admin | Catálogo para formulario |
| P56 | Workflow Rules | Catálogo: países | `GET /api/workflow-rules/countries` | GET | Soporte | Admin | Catálogo para formulario |
| P57 | Workflow Rules | Catálogo: tipos de recibo | `GET /api/workflow-rules/receipt-types` | GET | Soporte | Admin | Catálogo para formulario |
| P58 | Workflow Rules | Catálogo: roles | `GET /api/workflow-rules/roles` | GET | Soporte | Admin | Catálogo para formulario |

### CFDI / SAT (P59–P61)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P59 | CFDI / SAT | Parsear XML de comprobante | `POST /api/comprobantes/parse-xml` | POST | Core | Solicitante, N1, N2 | Upload XML para preview |
| P60 | CFDI / SAT | Crear comprobante fiscal | `POST /api/comprobantes/:receipt_id` | POST | Core | Solicitante, N1, N2 | Registro de CFDI al recibo |
| P61 | CFDI / SAT | Validar comprobante ante SAT | `GET /api/comprobantes/:id/validacion-sat` | GET | Core | CxP | Consulta SOAP al SAT |

### Tipo de Cambio / BER (P62–P66)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P62 | Tipo de Cambio | Obtener tasa de cambio | `GET /api/exchange-rate/rate` | GET | Soporte | Sistema | Consulta Banxico REST |
| P63 | Tipo de Cambio | Convertir moneda | `POST /api/exchange-rate/convert` | POST | Soporte | Sistema | Cálculo de conversión |
| P64 | Tipo de Cambio | Listar monedas soportadas | `GET /api/exchange-rate/currencies` | GET | Soporte | Sistema | Catálogo monedas |
| P65 | Tipo de Cambio | Historial de tasas | `GET /api/exchange-rate/history` | GET | Soporte | Sistema | Consulta histórica |
| P66 | Tipo de Cambio | Conversión FX pública | `GET /api/fx/convert` | GET | Soporte | Sistema | Conversión vía endpoint público |

### Políticas de Viaje (P67–P72)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P67 | Políticas | Listar políticas | `GET /api/policies` | GET | Gestión | Admin | Consulta políticas |
| P68 | Políticas | Obtener política por ID | `GET /api/policies/:id` | GET | Gestión | Admin | Detalle política |
| P69 | Políticas | Crear política | `POST /api/policies` | POST | Gestión | Admin | Formulario política |
| P70 | Políticas | Actualizar política | `PUT /api/policies/:id` | PUT | Gestión | Admin | Edición política |
| P71 | Políticas | Desactivar política | `DELETE /api/policies/:id` | DELETE | Gestión | Admin | Soft delete |
| P72 | Políticas | Preview recibo contra política | `POST /api/policies/preview` | POST | Core | CxP, Admin | Evaluación de topes |

### Categorías de Empleado (P73–P76)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P73 | Categorías Empleado | Listar categorías | `GET /api/employee-categories` | GET | Gestión | Admin | Consulta categorías |
| P74 | Categorías Empleado | Crear categoría | `POST /api/employee-categories` | POST | Gestión | Admin | Formulario categoría |
| P75 | Categorías Empleado | Actualizar categoría | `PUT /api/employee-categories/:id` | PUT | Gestión | Admin | Edición categoría |
| P76 | Categorías Empleado | Desactivar categoría | `DELETE /api/employee-categories/:id` | DELETE | Gestión | Admin | Soft delete |

### Viáticas Policy (P77–P78)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P77 | Viáticas Policy | Obtener política de viáticas | `GET /api/viaticas-policy` | GET | Gestión | Admin | Consulta configuración |
| P78 | Viáticas Policy | Crear/actualizar política de viáticas | `PUT /api/viaticas-policy` | PUT | Gestión | Admin | Upsert configuración |

### Reembolsos (P79–P85)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P79 | Reembolsos | Obtener límite de tiempo de reembolso | `GET /api/refunds/time-limit` | GET | Gestión | Admin, CxP | Consulta configuración |
| P80 | Reembolsos | Configurar límite de tiempo | `PUT /api/refunds/time-limit` | PUT | Gestión | Admin | Edición límite |
| P81 | Reembolsos | Listar excepciones pendientes | `GET /api/refunds/exceptions/pending` | GET | Soporte | Admin, CxP | Bandeja de excepciones |
| P82 | Reembolsos | Crear excepción de reembolso | `POST /api/refunds/exceptions` | POST | Core | CxP | Solicitar excepción |
| P83 | Reembolsos | Decidir excepción | `POST /api/refunds/exceptions/:id/decide` | POST | Core | Admin | Aprobar/rechazar excepción |
| P84 | Reembolsos | Dashboard de reembolsos por usuario | `GET /api/refunds/by-user/:userId` | GET | Soporte | CxP, Admin | Resumen por usuario |
| P85 | Reembolsos | Resumen de reembolso por solicitud | `GET /api/refunds/request/:requestId/summary` | GET | Soporte | CxP, Admin | Detalle solicitud |

### Organizations (P86–P92)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P86 | Organizations | Obtener mi organización | `GET /api/organizations/me` | GET | Soporte | Todos | Carga de contexto |
| P87 | Organizations | Crear organización | `POST /api/organizations` | POST | Gestión | Admin Ditta | Alta de cliente |
| P88 | Organizations | Listar organizaciones | `GET /api/organizations` | GET | Gestión | Admin Ditta | Panel cross-tenant |
| P89 | Organizations | Obtener organización por ID | `GET /api/organizations/:id` | GET | Gestión | Admin Ditta | Detalle org |
| P90 | Organizations | Actualizar organización | `PATCH /api/organizations/:id` | PATCH | Gestión | Admin Ditta | Edición org |
| P91 | Organizations | Activar organización | `POST /api/organizations/:id/activate` | POST | Gestión | Admin Ditta | Reactivar org |
| P92 | Organizations | Suspender organización | `POST /api/organizations/:id/suspend` | POST | Gestión | Admin Ditta | Suspender org |

### Onboarding Import (P93–P94)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P93 | Onboarding Import | Preview de importación de usuarios | `POST /api/onboarding-import/preview` | POST | Gestión | Admin | Upload CSV/JSON + validación |
| P94 | Onboarding Import | Aplicar importación de usuarios | `POST /api/onboarding-import/apply` | POST | Gestión | Admin | Persistir usuarios validados |

### Permisos / RBAC (P95–P119)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P95 | Permisos | Listar permisos | `GET /api/rbac/permissions` | GET | Gestión | Admin | Catálogo permisos |
| P96 | Permisos | Crear permiso | `POST /api/rbac/permissions` | POST | Gestión | Admin | Formulario permiso |
| P97 | Permisos | Actualizar permiso | `PATCH /api/rbac/permissions/:id` | PATCH | Gestión | Admin | Edición permiso |
| P98 | Permisos | Desactivar permiso | `DELETE /api/rbac/permissions/:id` | DELETE | Gestión | Admin | Soft delete |
| P99 | Permisos | Listar grupos de permisos | `GET /api/rbac/permission-groups` | GET | Gestión | Admin | Catálogo grupos |
| P100 | Permisos | Crear grupo de permisos | `POST /api/rbac/permission-groups` | POST | Gestión | Admin | Formulario grupo |
| P101 | Permisos | Obtener grupo de permisos | `GET /api/rbac/permission-groups/:id` | GET | Gestión | Admin | Detalle grupo |
| P102 | Permisos | Actualizar grupo de permisos | `PATCH /api/rbac/permission-groups/:id` | PATCH | Gestión | Admin | Edición grupo |
| P103 | Permisos | Desactivar grupo de permisos | `DELETE /api/rbac/permission-groups/:id` | DELETE | Gestión | Admin | Soft delete |
| P104 | Permisos | Agregar permisos a grupo | `POST /api/rbac/permission-groups/:id/permissions` | POST | Gestión | Admin | Asignación |
| P105 | Permisos | Quitar permiso de grupo | `DELETE /api/rbac/permission-groups/:id/permissions/:permissionId` | DELETE | Gestión | Admin | Desasignación |
| P106 | Permisos | Listar roles | `GET /api/rbac/roles` | GET | Gestión | Admin | Catálogo roles |
| P107 | Permisos | Crear rol | `POST /api/rbac/roles` | POST | Gestión | Admin | Formulario rol |
| P108 | Permisos | Actualizar rol | `PUT /api/rbac/roles/:roleId` | PUT | Gestión | Admin | Edición rol |
| P109 | Permisos | Eliminar rol | `DELETE /api/rbac/roles/:roleId` | DELETE | Gestión | Admin | Soft delete |
| P110 | Permisos | Agregar permisos a rol | `POST /api/rbac/roles/:roleId/permissions` | POST | Gestión | Admin | Asignación |
| P111 | Permisos | Quitar permiso de rol | `DELETE /api/rbac/roles/:roleId/permissions/:permissionId` | DELETE | Gestión | Admin | Desasignación |
| P112 | Permisos | Agregar grupos a rol | `POST /api/rbac/roles/:roleId/permission-groups` | POST | Gestión | Admin | Asignación |
| P113 | Permisos | Quitar grupo de rol | `DELETE /api/rbac/roles/:roleId/permission-groups/:groupId` | DELETE | Gestión | Admin | Desasignación |
| P114 | Permisos | Agregar permisos a usuario | `POST /api/rbac/users/:userId/permissions` | POST | Gestión | Admin | Asignación directa |
| P115 | Permisos | Quitar permiso de usuario | `DELETE /api/rbac/users/:userId/permissions/:permissionId` | DELETE | Gestión | Admin | Desasignación |
| P116 | Permisos | Agregar grupos a usuario | `POST /api/rbac/users/:userId/permission-groups` | POST | Gestión | Admin | Asignación directa |
| P117 | Permisos | Quitar grupo de usuario | `DELETE /api/rbac/users/:userId/permission-groups/:groupId` | DELETE | Gestión | Admin | Desasignación |
| P118 | Permisos | Obtener permisos efectivos de usuario | `GET /api/rbac/users/:userId/effective-permissions` | GET | Gestión | Admin | Consulta permisos resueltos |
| P119 | Permisos | Obtener mis permisos | `GET /api/user/me/permissions` | GET | Soporte | Todos | Carga de permisos propios |

### Notificaciones Push/In-App (P120–P126)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P120 | Notificaciones | Obtener clave pública VAPID | `GET /api/notifications/vapid-public-key` | GET | Soporte | Todos | Setup Web Push |
| P121 | Notificaciones | Obtener preferencias de notificación | `GET /api/notifications/preferences/:userId` | GET | Soporte | Todos | Consulta preferencias |
| P122 | Notificaciones | Actualizar preferencias de notificación | `PUT /api/notifications/preferences/:userId` | PUT | Gestión | Todos | Edición preferencias |
| P123 | Notificaciones | Suscribir a push notifications | `POST /api/notifications/subscribe` | POST | Core | Todos | Registro dispositivo |
| P124 | Notificaciones | Listar notificaciones | `GET /api/notifications/:userId` | GET | Soporte | Todos | Bandeja notificaciones |
| P125 | Notificaciones | Contar no leídas | `GET /api/notifications/:userId/unread-count` | GET | Soporte | Todos | Badge de notificaciones |
| P126 | Notificaciones | Marcar como leída | `PUT /api/notifications/:id/read` | PUT | Soporte | Todos | Click en notificación |

### API Keys (P127–P130)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P127 | API Keys | Generar API key | `POST /api/api-keys/generate` | POST | Gestión | Admin | Alta de clave M2M |
| P128 | API Keys | Revocar API key | `DELETE /api/api-keys/:id/revoke` | DELETE | Gestión | Admin | Baja de clave |
| P129 | API Keys | Listar API keys por organización | `GET /api/api-keys/org/:orgId` | GET | Gestión | Admin | Panel de claves |
| P130 | API Keys | Obtener logs de API key | `GET /api/api-keys/:id/logs` | GET | Gestión | Admin | Auditoría de uso |

### Contabilidad / Pólizas (P131–P145)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P131 | Contabilidad | Listar pólizas | `GET /api/accounts-payable/polizas` | GET | Soporte | CxP | Catálogo pólizas |
| P132 | Contabilidad | Exportar póliza por ID | `GET /api/accounts-payable/polizas/:poliza_id/export` | GET | Soporte | CxP | Descarga póliza |
| P133 | Contabilidad | Generar pólizas de solicitud | `POST /api/accounts-payable/polizas/:request_id/generar` | POST | Core | CxP | Generación automática |
| P134 | Contabilidad | Obtener solicitudes CxP | `GET /api/accounts-payable/requests` | GET | Soporte | CxP | Dashboard CxP |
| P135 | Contabilidad | Export contable por solicitud | `GET /api/accounts-payable/accounting-export/:request_id` | GET | Soporte | CxP | Exportación individual |
| P136 | Contabilidad | Export contable por rango | `GET /api/accounts-payable/accounting-export` | GET | Soporte | CxP | Exportación batch |
| P137 | Contabilidad | Listar catálogo de cuentas | `GET /api/chart-of-accounts` | GET | Gestión | Admin, CxP | Catálogo contable |
| P138 | Contabilidad | Obtener cuenta contable | `GET /api/chart-of-accounts/:id` | GET | Gestión | Admin, CxP | Detalle cuenta |
| P139 | Contabilidad | Crear cuenta contable | `POST /api/chart-of-accounts` | POST | Gestión | Admin | Alta cuenta |
| P140 | Contabilidad | Actualizar cuenta contable | `PUT /api/chart-of-accounts/:id` | PUT | Gestión | Admin | Edición cuenta |
| P141 | Contabilidad | Desactivar cuenta contable | `DELETE /api/chart-of-accounts/:id` | DELETE | Gestión | Admin | Soft delete |
| P142 | Contabilidad | Export contable consolidado | `GET /api/export/contable` | GET | Soporte | CxP | Exportación integrada |
| P143 | Contabilidad | Preview contable (API externa) | `GET /api/external/accounting/preview` | GET | Soporte | Operador ERP | Smoke test M2M |
| P144 | Contabilidad | Export por solicitud (API externa) | `GET /api/external/accounting-export/:request_id` | GET | Soporte | Operador ERP | Export M2M individual |
| P145 | Contabilidad | Export por rango (API externa) | `GET /api/external/accounting-export` | GET | Soporte | Operador ERP | Export M2M batch |
| P146 | Contabilidad | Export contable ERP alias | `GET /api/external/export/contable` | GET | Soporte | Operador ERP | Alias para ERP |

### Gasto Tramo (P147–P148)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P147 | Gasto Tramo | Crear gasto por tramo | `POST /api/gasto-tramo/:id/tramos/:tramo_id/gastos` | POST | Core | Solicitante, N1, N2 | Registro gasto a tramo |
| P148 | Gasto Tramo | Resumen de tramos | `GET /api/gasto-tramo/:id/resumen-tramos` | GET | Soporte | Solicitante, N1, N2 | Vista consolidada |

### Reportes (P149)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P149 | Reportes | Gastos por centro de costo | `GET /api/reports/expenses-by-cc` | GET | Soporte | Admin, CxP | Reporte analítico |

### Comentarios de Solicitud (P150–P152)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P150 | Comentarios | Crear comentario en solicitud | `POST /api/request-comments/:id/comments` | POST | Core | Todos | Agregar comentario |
| P151 | Comentarios | Leer comentarios de solicitud | `GET /api/request-comments/:id/comments` | GET | Soporte | Todos | Paginación de comentarios |
| P152 | Comentarios | Stream de comentarios (SSE) | `GET /api/request-comments/:id/comments/stream` | SSE | Soporte | Todos | Actualización en tiempo real |

### Flights / Hotels (P153–P155)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P153 | Flights | Buscar vuelos | `POST /api/flights/search` | POST | Core | Agencia | Búsqueda Duffel |
| P154 | Hotels | Buscar hoteles | `POST /api/hotels/search` | POST | Core | Agencia | Búsqueda Duffel |
| P155 | Hotels | Obtener tarifas de hotel | `POST /api/hotels/search-results/:search_result_id/rates` | POST | Core | Agencia | Fetch rates Duffel |

### Travel Agent — extras (P156–P157)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P156 | Viaje | Guardar vuelo seleccionado | `PUT /api/travel-agent/travel-request/:request_id/selected-flight` | PUT | Core | Agencia | Selección de oferta |
| P157 | Viaje | Guardar hotel seleccionado | `PUT /api/travel-agent/travel-request/:request_id/selected-hotel` | PUT | Core | Agencia | Selección de oferta |

### Archivos — extras (P158–P159)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P158 | Archivos | Upload genérico a S3 | `POST /api/files/upload` | POST | Core | Todos | Upload archivos |
| P159 | Archivos | Download por ID desde S3 | `GET /api/files/:id/download` | GET | Soporte | Todos | Download archivos |

### Admin — extras (P160–P163)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P160 | Admin | Sincronizar empleados | `POST /api/admin/employees/sync` | POST | Gestión | Admin | Sincronización externa |
| P161 | Admin | Listar empleados | `GET /api/admin/employees` | GET | Gestión | Admin | Consulta empleados |
| P162 | Admin | Validar ciclo de manager | `POST /api/admin/employees/validate-manager-cycle` | POST | Gestión | Admin | Prevención de ciclos |
| P163 | Admin | Vincular usuario-empleado | `PUT /api/admin/users/:user_id/employee-link` | PUT | Gestión | Admin | Enlace SAP |

### Usuario — extras (P164)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P164 | Usuario | Obtener solicitudes de aprobador | `GET /api/user/get-approver-requests/:status_id/:n?` | GET | Soporte | N1, N2 | Dashboard aprobador |

### Cron Jobs (P165–P166)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P165 | Cron | Escalamiento automático N1→N2 | — | Cron | Core | Sistema | `escalationJob` — cada hora (`0 * * * *`), escala solicitudes status=2 con >48h a status=3 |
| P166 | Cron | Bloqueo de reembolsos vencidos | — | Cron | Core | Sistema | `refundDeadlineJob` — diario 03:00 (`0 3 * * *`), bloquea solicitudes que exceden plazo |

### Tenant Extension (P167)

| ID | Dominio | Proceso | Endpoint | Método | Tipo | Actor(es) | Trigger / Mecanismo |
|----|---------|---------|----------|--------|------|-----------|---------------------|
| P167 | Tenant Extension | Auto-inyección de organization_id + RLS | — | Evento | Soporte | Sistema | `prisma/tenantExtension.js` — auto-scope de 39 modelos con `set_config('app.current_organization_id')` + bypass para Admin Ditta |

---

## Resumen por dominio

| Dominio | Procesos | IDs |
|---------|----------|-----|
| Auth | 2 | P01–P02 |
| Usuario | 5 | P03–P06, P164 |
| Solicitudes | 10 | P07–P16 |
| Gastos | 3 | P17–P19 |
| Aprobación | 3 | P20–P22 |
| Viaje | 7 | P23–P27, P156–P157 |
| Archivos | 5 | P28–P30, P158–P159 |
| Admin | 9 | P31–P35, P160–P163 |
| Prisma Extension | 5 | P36–P40 |
| Notificaciones (multicanal) | 1 | P41 |
| Solicitud Workflow | 4 | P42–P45 |
| Approval Substitutes | 3 | P46–P48 |
| Inbox | 1 | P49 |
| Workflow Rules | 9 | P50–P58 |
| CFDI / SAT | 3 | P59–P61 |
| Tipo de Cambio / BER | 5 | P62–P66 |
| Políticas de Viaje | 6 | P67–P72 |
| Categorías Empleado | 4 | P73–P76 |
| Viáticas Policy | 2 | P77–P78 |
| Reembolsos | 7 | P79–P85 |
| Organizations | 7 | P86–P92 |
| Onboarding Import | 2 | P93–P94 |
| Permisos / RBAC | 25 | P95–P119 |
| Notificaciones Push/In-App | 7 | P120–P126 |
| API Keys | 4 | P127–P130 |
| Contabilidad / Pólizas | 16 | P131–P146 |
| Gasto Tramo | 2 | P147–P148 |
| Reportes | 1 | P149 |
| Comentarios | 3 | P150–P152 |
| Flights / Hotels | 3 | P153–P155 |
| Cron Jobs | 2 | P165–P166 |
| Tenant Extension | 1 | P167 |
| **Total** | **167** | P01–P167 |
