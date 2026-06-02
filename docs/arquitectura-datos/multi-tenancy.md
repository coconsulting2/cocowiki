# Multi-Tenant — Ditta como organización ROOT

## TL;DR

El sistema es multi-tenant. **Ditta** es la única organización con `kind=ROOT` y es la única que puede crear nuevas organizaciones cliente (`kind=CLIENT`). Todo dato operativo (solicitudes, comprobantes, CFDIs, alertas, etc.) y toda configuración editable (roles, permission groups, alert messages, receipt types, plantillas de notificación, catálogo contable, integraciones, etc.) están scoped por `organizationId`.

## Arquitectura

### Identificación del tenant
- **JWT claim `organization_id`** (BigInt como string en payload). Se incluye en el token al hacer login (`services/userService.js`).
- **Header `X-Organization-Id`** (override para super-admin Ditta). Solo respetado si el JWT tiene `organization_kind=ROOT`. Permite a Ditta ver/operar datos de una org cliente sin necesitar cambiar de usuario.

**Cookies de sesión** (httpOnly, establecidas por `controllers/userController.js` en el login):
`token`, `role`, `username`, `id`, `department_id`, `no_empleado`.

### Tres capas de aislamiento (defense in depth)

1. **Prisma Client Extension** (`prisma/tenantExtension.js`)
   Inyecta `where.organizationId = ctx.organizationId` en READ_OPS (`findUnique`, `findUniqueOrThrow`, `findFirst`, `findFirstOrThrow`, `findMany`, `count`, `aggregate`, `groupBy`) y en mutaciones (`update*`, `delete*`). Inyecta `data.organizationId = ctx.organizationId` en `create*` y `upsert`. Lista cerrada de modelos tenant-scoped (`TENANT_SCOPED_MODELS`).

   > La extension NO ejecuta `set_config` ni ningún GUC. Se limita a inyectar filtros de aplicación sobre los args de Prisma. El GUC de RLS lo gestiona el middleware `applyRlsForRequest` (ver punto 2).

2. **Postgres Row-Level Security (RLS)**
   Cada tabla tenant-scoped tiene `ENABLE ROW LEVEL SECURITY` + política `tenant_isolation` (migration `20260512000000_multi_tenant_baseline`):
   ```sql
   USING (
     <col> = NULLIF(current_setting('app.current_organization_id', true), '')::bigint
     OR current_setting('app.bypass_tenant', true) = 'on'
   )
   WITH CHECK (
     <col> = NULLIF(current_setting('app.current_organization_id', true), '')::bigint
     OR current_setting('app.bypass_tenant', true) = 'on'
   )
   ```
   El segundo argumento `true` en `current_setting` indica *missing-ok* (evita excepción si el GUC no existe). El `NULLIF(..., '')` protege contra GUC vacío que de otro modo haría fallar el cast a `bigint`.

   El GUC se setea desde `applyRlsSetting` (en `database/config/rlsConnection.js`), que a su vez es invocado por el middleware `applyRlsForRequest`. Este middleware se monta automáticamente en toda ruta protegida a través de `requirePermission`/`requireAnyPermission`.

   **Cadena de ejecución en cada request protegido:**
   ```
   authenticateToken → tenantContextMiddleware → applyRlsForRequest → loadPermissions → authorizePermission
   ```

   `applyRlsForRequest` ejecuta `set_config('app.current_organization_id', $orgId, false)` (session-scoped, no transaccional) y `set_config('app.bypass_tenant', ...)`. Aunque la extension de Prisma falle, RLS bloquea queries cross-tenant.

3. **AsyncLocalStorage** (`middleware/tenantContext.js`)
   El context fluye sin pasar args manualmente. Cualquier código que use el `prisma` cliente del singleton consume `getTenantContext()` automáticamente.

### Bypass de Ditta (super-admin) y diseño de dos puertas

El header `X-Organization-Id` solo es respetado si `organization_kind === ROOT` en el JWT (`tenantContext.js`). El middleware establece `bypassTenant = (activeOrgId !== jwtOrgId)`: si un usuario ROOT envía `X-Organization-Id: 1` (su propia org), `bypassTenant` permanece `false` — el bypass solo se activa cuando la org activa difiere de la org del JWT.

La validación del permiso `organization:impersonate` ocurre después, a nivel de route-handler, como segunda puerta. El middleware de tenant solo verifica `organization_kind === ROOT`; la autorización granular la hace el handler.

Flujo completo cuando Ditta impersona una org cliente:
1. `tenantContextMiddleware` detecta `isRoot=true` + header → `activeOrgId = <orgCliente>`, `bypassTenant = true`.
2. `applyRlsForRequest` setea `app.bypass_tenant=on`.
3. La extension de Prisma ve `bypassTenant=true` → no inyecta filtros de `where`.
4. RLS permite el paso por la cláusula `current_setting('app.bypass_tenant', true) = 'on'`.
5. El route-handler verifica el permiso `organization:impersonate` como segunda puerta.

Sin header, Ditta opera dentro de su propia org (id=1) como cualquier otra.

### `applyRlsSetting` vs `withRls`

| Helper | Alcance del GUC | Caso de uso |
|---|---|---|
| `applyRlsSetting` | Session-scoped (`set_config(..., false)`) | Cada request HTTP via `applyRlsForRequest`. El siguiente request al pool sobrescribe el valor. |
| `withRls` | Transaccional (`SET LOCAL`, `set_config(..., true)`) | Operaciones cross-org que necesitan aislamiento estricto, p. ej. onboarding: `withRls(1n, { bypass: true }, ...)`. El GUC expira al cerrar la transacción, sin riesgo de filtrado al pool. |

## Modelo de datos

### Globales (sin `organization_id`)
- `Permission` — strings atómicos hard-coded por el código.
- `RequestStatus` — IDs hard-coded en `prisma/middleware.js` (máquina de estados).
- `Country`, `City` — catálogo geográfico.
- `organizaciones` — la tabla raíz misma; Ditta debe poder listar todas.

### Per-org (todo lo demás)
- Datos operativos: `User`, `Request`, `Receipt`, `Route`, `RouteRequest`, `GastoTramo`, `CfdiComprobante`, `Alert`, `SolicitudHistorial`, `Notification`, `UserPreference`, `PushSubscription`.
- Configuración: `Role`, `Department`, `PermissionGroup`, `ReceiptType`, `AlertMessage`, `NotificationTemplate`, `ChartOfAccount`, `AccountingDocType`, `AccountingSociety`, `OrganizationIntegration`.
- M2-006 (políticas y reembolso): `EmployeeCategory`, `TravelPolicy`, `ReimbursementTimeLimit`, `WorkflowRule`, `PolicyException`.
- Módulos contables/RRHH: `AccountingPoliza`, `Empleado`, `AnticipoPolizaSnapshot`.
- Seguridad: `ApiKey`.
- Otros: `Proveedor`, `ApprovalSubstitute`, `UserPermission`, `UserPermissionGroup`.

### Herencia vía padre (sin FK directa pero RLS por JOIN)
- `PermissionGroupItem` → `PermissionGroup.organization_id`
- `RolePermission`, `RolePermissionGroup` → `Role.organization_id`
- `PolicyExpenseCap` → `TravelPolicy.org_id`

## Roles

| Role               | Scope          | Notas |
|--------------------|----------------|-------|
| `Admin Ditta`      | Solo en Ditta  | Único con grupo `DittaSuperAdmin` |
| `Administrador`    | Cada org       | Gestiona su propia org |
| `N1`, `N2`         | Cada org       | Aprobadores con umbrales |
| `Solicitante`      | Cada org       | Solicita viáticos |
| `Cuentas por pagar`| Cada org       | Valida comprobantes |
| `Agencia de viajes`| Cada org       | Reserva |

Cada org puede crear roles custom adicionales (RF-50). Los roles default tienen `is_system=true` y no se pueden borrar.

## Permisos nuevos (multi-tenant)

```
organization:create     organization:list_all    organization:read
organization:update     organization:activate    organization:suspend
organization:impersonate organization:manage_any

integration:read         integration:write
accounting_catalog:read  accounting_catalog:write
notification_template:read notification_template:write
receipt_type:write       alert_message:write
```

Asignados al grupo `DittaSuperAdmin` (solo en org ROOT). El grupo `OrgAdmin` (en cada org) recibe los permisos de configuración de la org propia.

## Onboarding de una nueva org cliente

```
POST /api/organizations
  Authorization: Bearer <jwt_super_admin_ditta>
  Body: { nombre, rfc?, razonSocial?, timezone?, baseCurrency?,
          adminEmail, adminNombre, adminPassword }
```

Flujo:
1. `organizationService.createOrganization` corre dentro de `withRls(1n, { bypass: true })`.
2. `prisma.organization.create` crea la org con `kind=CLIENT, status=CONFIGURING`.
3. `bootstrapOrganizationCatalogs(prisma, org.id)` siembra roles default, permission groups, alert messages, receipt types, plantillas de notificación, catálogo contable, time limit.
4. `ensureOrganizationAdmin` crea el user `Administrador` inicial con la contraseña proporcionada.
5. La org queda lista para ser activada (`POST /api/organizations/:id/activate`).

## RFC opcional

`Organization.rfc` es nullable. La unicidad se enforza con un índice parcial:
```sql
CREATE UNIQUE INDEX organizaciones_rfc_unique
  ON organizaciones(rfc) WHERE rfc IS NOT NULL;
```
Permite onboardear orgs en proceso de constitución, sandbox o demos. Validación SAT solo aplica si el campo se llena.

## Suspensión

`POST /api/organizations/:id/suspend` cambia `status=SUSPENDED`. El próximo login del usuario de esa org se rechaza con HTTP 403 (`services/userService.js` valida `organization_status`). Sesiones activas se invalidan automáticamente porque cada request revalida.

La org ROOT (Ditta) **no puede ser suspendida** (constraint a nivel servicio).

## Backfill de datos existentes

La migration `20260512000000_multi_tenant_baseline` agrega `organization_id` a todas las tablas existentes y hace backfill derivando desde el padre cuando hay FK indirecta:
- `Request.organization_id` ← `User.organization_id`
- `Receipt.organization_id` ← `Request.organization_id`
- `CfdiComprobante.organization_id` ← `Receipt.organization_id`
- etc.

Fallback para huérfanos en dev: TechCorp (id=2). En producción se debe correr un script de auditoría previo (`scripts/auditTenantBackfill.js` — TBD) que valide 0 huérfanos antes de aplicar la migration.

## Verificación

### Smoke test manual

```bash
# 1. Reset + seed con data dev.
cd TC3005B.501-Backend
bun run dummy_db

# 2. Login como super-admin Ditta.
curl -X POST http://localhost:3000/api/user/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin_ditta","password":"Ditta!Admin#2026"}'
# → { token, organization_id: "1", organization_kind: "ROOT", ... }

# 3. Crear org nueva.
curl -X POST http://localhost:3000/api/organizations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Prueba SA","adminEmail":"admin@prueba.com","adminNombre":"Admin Prueba","adminPassword":"Secret123"}'
# → { organization: { id: "4", ..., status: "CONFIGURING" } }

# 4. Verificar aislamiento: login como admin@techcorp.test, intentar leer org de Prueba.
curl -H "Authorization: Bearer <token_techcorp>" \
  http://localhost:3000/api/organizations/4
# → 404 (RLS bloquea, ni siquiera filtra existencia)
```

### Tests de aislamiento

- `tests/services/organizationService.test.js` — CRUD + validaciones.
- `tests/middleware/tenantContext.test.js` — AsyncLocalStorage + override por header.
- `tests/prisma/tenantExtension.test.js` — Inyección automática de where/data + bypass.

Mapeo a criterios de salida: **XC-07** (cero leaks entre orgs), **XF-07** (aislamiento multi-tenant validado).

## Variables de entorno nuevas

```
DITTA_ADMIN_INITIAL_PASSWORD=     # Password inicial del super-admin. Rotable post-deploy.
DITTA_RFC=                        # RFC de Ditta (opcional). Si vacío, null en BD.
TOKEN_GRACE_PERIOD_END=           # ISO date. Tokens viejos sin organization_id se rechazan tras esta fecha.
                                  # Si NO se define, el grace period termina 24h después del inicio del proceso
                                  # (Date.now() + 24h al arrancar). No equivale a "nunca".
```

## Trabajo futuro (post este PR)

- Refactor de `mailService`, `wiseService`, `satService`, `pushNotificationService` para usar `integrationResolver(orgId, provider)` en lugar de leer env vars directas.
- Scoping completo de GridFS (metadata `organizationId`).
- Auditoría + enforce de prefijo `{orgId}/...` en S3 keys.
- Refactor de schedulers (`approvalSubstituteCron` y otros) a `runForEachOrg`.
- Pantallas frontend para configurar el catálogo contable, plantillas de notificación, integraciones desde el admin de cada org.
- Frontend org switcher integrado al topbar (hoy solo está en `/admin/organizations`).
