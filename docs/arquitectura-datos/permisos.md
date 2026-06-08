# Sistema de permisos granulares

| Metadato | Valor |
|---|---|
| **Versión** | 1.1.0 |
| **Última actualización** | 2026-06-02 |
| **Fuente** | [permissionMiddleware.js](../../../TC3005B.501-Backend/middleware/permissionMiddleware.js), [prisma/seed.js](../../../TC3005B.501-Backend/prisma/seed.js), [prisma/seedHelpers/bootstrapOrganization.js](../../../TC3005B.501-Backend/prisma/seedHelpers/bootstrapOrganization.js), [config/tenantApplicantCapability.js](../../../TC3005B.501-Backend/config/tenantApplicantCapability.js), [modelo-er.md](modelo-er.md#sistema-de-permisos-granulares-rbac--directo-a-usuario) |

## TL;DR para agregar un permiso nuevo

1. Edita `TC3005B.501-Backend/prisma/seed.js` → agrega el permiso a `PERMISSION_CATALOG` (catálogo **global** de permisos atómicos) y, si forma parte de un rol default, al grupo correspondiente en `PERMISSION_GROUPS_DEFAULTS` (que vive en `prisma/seedHelpers/bootstrapOrganization.js`, no en `seed.js`).
2. Reinicia el stack: `bun run docker:dev:down && bun run docker:dev`. El migrate service re-aplica la seed de referencia (idempotente) automáticamente — tus compañeros obtendrán el permiso al próximo `up` sin hacer nada.
3. En la ruta backend: `...requirePermission("mi_resource:mi_action")`.
4. En React: `hasPermission(perms, "mi_resource:mi_action")` — los permisos se cargan al login y están en el store.

No necesitas migraciones de Prisma (usamos `db push`), no necesitas tocar JWTs, no necesitas reiniciar nada manualmente más allá de `docker:dev:down && docker:dev`.

---

## Arquitectura en una página

```
Cliente ──(POST /api/user/login)──> Backend
                                       │
                                       ├─ JWT con { user_id, role, ip }
                                       └─ Body JSON:
                                          { token, role, permissions: ["travel_request:create", ...] }
                                                                        ▲
                                                                        │
                         ┌──────────────────────────────────────────────┘
                         │ (resuelto por permissionService.loadEffectivePermissions)
                         │
              ┌──────────┴───────────┐
              │                      │
       role.rolePermissions    role.rolePermissionGroups[*].items
              ∪                      ∪
       user.userPermissions    user.userPermissionGroups[*].items
              └──────────┬───────────┘
                         │ unión deduplicada → Set<permission_code>
                         │
Protege rutas:   ...requirePermission("travel_request:authorize")
                 ↓
                 [authenticateToken, tenantContextMiddleware, applyRlsForRequest,
                  loadPermissions, authorizePermission]
                            ↑
        nunca se puede saltar authenticateToken (orden garantizado por el helper);
        tenantContextMiddleware + applyRlsForRequest fijan el organization_id y la RLS
        de Postgres antes de resolver permisos
```

### Modelos Prisma involucrados

Ver [`modelo-er.md`](modelo-er.md#sistema-de-permisos-granulares-rbac--directo-a-usuario) para el diagrama Mermaid completo.

| Tabla | Propósito |
|---|---|
| `Permission` | Permiso atómico con `code` único en formato `resource:action`. |
| `PermissionGroup` | Bundle reutilizable de permisos. |
| `Permission_Group_Item` | Membresía grupo ↔ permiso. |
| `Role_Permission` | Grant directo de un permiso a un rol. |
| `Role_Permission_Group` | Grant de un grupo a un rol (se expande al resolver). |
| `User_Permission` | Grant directo de un permiso a un usuario (aditivo sobre el rol). |
| `User_Permission_Group` | Grant de un grupo a un usuario (aditivo). |

### Semántica

- **Aditivo únicamente** (v1). No existe `deny` explícito: los permisos del usuario se **suman** a los del rol. Para "quitar" un permiso a un usuario específico, tienes que cambiarlo de rol.
- **Sin jerarquía entre roles**. N2 no "hereda" de N1: cada uno está asociado al mismo grupo `TravelRequestApprover` que contiene `travel_request:authorize`.
- **Sin caché entre requests**. Cada request autenticado resuelve permisos con **una** query Prisma (findUnique + includes anidados). Lo suficientemente rápido para el tamaño actual; si hace falta, se puede memoizar en el JWT o en Redis.

---

## Catálogo actual (referencia)

El catálogo de permisos atómicos es **global** (no está scopeado por organización) y se define en [`prisma/seed.js`](../../../TC3005B.501-Backend/prisma/seed.js) bajo `PERMISSION_CATALOG`. Los **grupos**, los **roles** y su asignación son **por organización** y se siembran vía `bootstrapOrganizationCatalogs()` en [`prisma/seedHelpers/bootstrapOrganization.js`](../../../TC3005B.501-Backend/prisma/seedHelpers/bootstrapOrganization.js) (`PERMISSION_GROUPS_DEFAULTS`, `DEFAULT_ROLES`, `ROLE_GROUP_ASSIGNMENTS_DEFAULT`).

A la fecha de este documento el catálogo tiene **48 permisos atómicos** repartidos en **21 namespaces** (recursos). Cualquier alta/baja requiere release del software porque los middlewares dependen de strings literales.

### Permisos

| Recurso | Código | Descripción |
|---|---|---|
| `travel_request` | `travel_request:create` | Crear una solicitud de viaje. |
| `travel_request` | `travel_request:view_own` | Ver las solicitudes propias. |
| `travel_request` | `travel_request:view_any` | Ver cualquier solicitud de la organización. |
| `travel_request` | `travel_request:edit_own` | Editar las solicitudes propias. |
| `travel_request` | `travel_request:submit` | Enviar una solicitud a revisión. |
| `travel_request` | `travel_request:cancel` | Cancelar una solicitud. |
| `travel_request` | `travel_request:authorize` | Autorizar/rechazar una solicitud (N1/N2). |
| `travel_agent` | `travel_agent:attend` | Atender reservas como agencia de viajes. |
| `accounts_payable` | `accounts_payable:attend` | Atender el flujo de cuentas por pagar. |
| `accounting` | `accounting:export` | Exportar la información contable. |
| `receipt` | `receipt:upload` | Subir comprobantes. |
| `receipt` | `receipt:delete_own` | Eliminar comprobantes propios. |
| `receipt` | `receipt:validate` | Validar comprobantes (cuentas por pagar). |
| `receipt` | `receipt:view_sat` | Ver los datos SAT/CFDI del comprobante. |
| `expense` | `expense:view` | Ver gastos. |
| `expense` | `expense:submit` | Enviar gastos para comprobación. |
| `expense` | `expense:authorize_exception` | Autorizar gastos fuera de política (excepción). |
| `authorizer` | `authorizer:view_alerts` | Ver las alertas del autorizador. |
| `user` | `user:view_self` | Ver el perfil propio. |
| `user` | `user:list` | Listar usuarios de la organización. |
| `user` | `user:create` | Crear usuarios. |
| `user` | `user:edit` | Editar usuarios. |
| `user` | `user:manage_permissions` | Gestionar permisos/grupos directos de un usuario. |
| `permission` | `permission:read` | Leer el catálogo de permisos. |
| `permission` | `permission:write` | Crear/editar/desactivar permisos del catálogo. |
| `permission_group` | `permission_group:manage` | Gestionar grupos de permisos. |
| `role` | `role:manage_permissions` | Gestionar los permisos/grupos asignados a un rol. |
| `policy` | `policy:read` | Leer las políticas de viáticos (M2-006). |
| `policy` | `policy:manage` | Crear/editar políticas de viáticos. |
| `api_key` | `api_key:manage` | Gestionar las API keys de integración de la organización (M3-004). |
| `organization` | `organization:create` | Crear organizaciones cliente. |
| `organization` | `organization:list_all` | Listar todas las organizaciones (cross-tenant). |
| `organization` | `organization:read` | Leer los datos de una organización. |
| `organization` | `organization:update` | Actualizar los datos de una organización. |
| `organization` | `organization:activate` | Activar una organización. |
| `organization` | `organization:suspend` | Suspender una organización. |
| `organization` | `organization:impersonate` | Impersonar (operar como) otra organización. |
| `organization` | `organization:manage_any` | Gestionar cualquier organización (cross-tenant). |
| `integration` | `integration:read` | Leer la configuración de integraciones. |
| `integration` | `integration:write` | Editar la configuración de integraciones. |
| `accounting_catalog` | `accounting_catalog:read` | Leer el catálogo contable. |
| `accounting_catalog` | `accounting_catalog:write` | Editar el catálogo contable. |
| `notification_template` | `notification_template:read` | Leer las plantillas de notificación. |
| `notification_template` | `notification_template:write` | Editar las plantillas de notificación. |
| `receipt_type` | `receipt_type:write` | Gestionar los tipos de comprobante. |
| `alert_message` | `alert_message:write` | Gestionar los mensajes de alerta. |
| `onboarding` | `onboarding:import` | Importar onboarding masivo de organizaciones/usuarios (M3-007). |
| `workflow` | `workflow:manage` | Gestionar las reglas de flujo de trabajo (solo admin de la org). |

### Grupos y su asignación a roles

Cada rol **acumula varios grupos** (semántica aditiva, ver más abajo). Por ejemplo, N1 y N2 obtienen `[BaseColaborador, TravelRequestAuthor, TravelRequestApprover]`: heredan toda la capacidad de solicitante **y además** la de aprobador. La columna "Rol(es) asignado(s)" lista los roles default que incluyen cada grupo según `ROLE_GROUP_ASSIGNMENTS_DEFAULT`.

| Grupo | Rol(es) asignado(s) | Incluye |
|---|---|---|
| `BaseColaborador` | **Todos los roles** | `user:view_self` (mínimo para cualquier usuario). |
| `TravelRequestAuthor` | **Todos los roles** | Capacidad de solicitante: se resuelve desde `TENANT_APPLICANT_CAPABILITY_CODES` (ver nota abajo) — `travel_request:create`/`view_own`/`view_any`/`edit_own`/`submit`/`cancel`, `receipt:upload`/`delete_own`/`view_sat`, `expense:view`/`submit`, `policy:read`, `user:view_self`. |
| `TravelRequestApprover` | N1, N2 | Todo lo del solicitante **+** `travel_request:authorize` + `authorizer:view_alerts` + `expense:authorize_exception`. |
| `TravelAgencyOps` | Agencia de viajes | `travel_agent:attend` + `travel_request:view_any` + `user:view_self`. |
| `AccountsPayableOps` | Cuentas por pagar | `accounts_payable:attend` + `accounting:export` + `receipt:validate` + `receipt:view_sat` + `expense:view` + `travel_request:view_any` + `policy:read` + `accounting_catalog:read` + `user:view_self`. |
| `OrgAdmin` | Administrador | Gestión de usuarios (`user:list`/`create`/`edit`), del sistema de permisos (`permission:read`/`write`, `permission_group:manage`, `role:manage_permissions`, `user:manage_permissions`), políticas (`policy:read`/`manage`), `receipt_type:write`, `alert_message:write`, catálogo contable (`accounting_catalog:read`/`write`), plantillas de notificación (`notification_template:read`/`write`), integraciones (`integration:read`/`write`), `organization:read`/`update`, `workflow:manage` y `user:view_self`. |
| `TravelNotifyOnly` | Observador | `travel_request:view_any` + `authorizer:view_alerts` + `user:view_self` (solo lectura/alertas, sin autorizar). |
| `DittaSuperAdmin` | Admin Ditta (solo org ROOT) | Super-admin cross-tenant — ver tabla dedicada abajo. |

> **Nota sobre `TravelRequestAuthor`.** Sus permisos **no** se enumeran a mano en el grupo: se resuelven a partir de `TENANT_APPLICANT_CAPABILITY_CODES` en [`config/tenantApplicantCapability.js`](../../../TC3005B.501-Backend/config/tenantApplicantCapability.js), que es la fuente de verdad de la "capacidad solicitante" del tenant. Esa lista incluye, entre otros, `receipt:view_sat`, `policy:read` y `user:view_self`. Por eso cualquier usuario activo de una org obtiene el flujo mínimo de solicitudes/comprobantes propios, aunque su rol no sea Solicitante.

### Roles default por organización

`bootstrapOrganizationCatalogs()` siembra estos roles en toda organización (`DEFAULT_ROLES`), más sus límites de monto de aprobación:

| Rol | Grupos asignados (`ROLE_GROUP_ASSIGNMENTS_DEFAULT`) | `maxApprovalAmount` |
|---|---|---|
| Solicitante | `BaseColaborador`, `TravelRequestAuthor` | — |
| N1 | `BaseColaborador`, `TravelRequestAuthor`, `TravelRequestApprover` | 50 000 |
| N2 | `BaseColaborador`, `TravelRequestAuthor`, `TravelRequestApprover` | 500 000 |
| Agencia de viajes | `BaseColaborador`, `TravelRequestAuthor`, `TravelAgencyOps` | — |
| Cuentas por pagar | `BaseColaborador`, `TravelRequestAuthor`, `AccountsPayableOps` | — |
| Administrador | `BaseColaborador`, `TravelRequestAuthor`, `OrgAdmin` | — |
| Observador | `BaseColaborador`, `TravelRequestAuthor`, `TravelNotifyOnly` | — |

Cada org puede además crear roles custom y reasignar grupos en caliente vía los endpoints admin (ver más abajo).

### Grupo y rol exclusivos de la org ROOT (Ditta)

La organización ROOT (**Ditta**, id=1) se bootstrappea con `includeDittaSuperAdmin: true`, lo que añade el grupo `DittaSuperAdmin` y el rol **`Admin Ditta`** (mapeado a `[BaseColaborador, TravelRequestAuthor, DittaSuperAdmin]`). Las organizaciones cliente se siembran con `includeDittaSuperAdmin: false`, así que **no** tienen ni este grupo ni este rol.

| Grupo | Rol | Permisos |
|---|---|---|
| `DittaSuperAdmin` | `Admin Ditta` | Las 8 acciones de `organization:*` (`create`, `list_all`, `read`, `update`, `activate`, `suspend`, `impersonate`, `manage_any`); gestión de usuarios (`user:list`/`create`/`edit`); sistema de permisos (`permission:read`/`write`, `permission_group:manage`, `role:manage_permissions`, `user:manage_permissions`); `policy:read`/`manage`; `integration:read`/`write`; `accounting_catalog:read`/`write`; `notification_template:read`/`write`; `receipt_type:write`; `alert_message:write`; **`api_key:manage`**; **`onboarding:import`**; y `user:view_self`. |

> **`api_key:manage` y `onboarding:import` son EXCLUSIVOS de `DittaSuperAdmin`.** Ningún grupo default de una org cliente los incluye; son capacidades del super-admin cross-tenant.

---

## Cómo agregar un permiso nuevo a una feature

### 1. Definir el permiso en el seed

En `TC3005B.501-Backend/prisma/seed.js`, añade una entrada al array `PERMISSION_CATALOG`:

```js
{ code: "expense:export", resource: "expense", action: "export", description: "Export expenses to CSV" },
```

El **`code`** es el que usarás en el middleware — convención `resource:action`, todo minúsculas, máx. 80 caracteres.

### 2. Asignarlo a un grupo (o directo al rol)

Si el permiso forma parte de un rol ya existente, agrégalo al array `permissions` del grupo correspondiente en `PERMISSION_GROUPS_DEFAULTS` (en `prisma/seedHelpers/bootstrapOrganization.js`):

```js
{
  groupName: "AccountsPayableOps",
  description: "Cuentas por pagar — valida comprobantes y exporta contabilidad",
  permissions: [
    "accounts_payable:attend",
    "accounting:export",
    "expense:export",          // ← nuevo
    "receipt:validate", "receipt:view_sat",
    "expense:view",
    "travel_request:view_any",
    "policy:read",
    "accounting_catalog:read",
    "user:view_self",
  ],
},
```

Si necesitas un grupo nuevo, agrega un objeto a `PERMISSION_GROUPS_DEFAULTS` y un mapeo en `ROLE_GROUP_ASSIGNMENTS_DEFAULT` (ambos en `bootstrapOrganization.js`). Recuerda que un rol puede acumular **varios** grupos. Para un permiso que deba pertenecer a la capacidad solicitante de todo el tenant, agrégalo a `TENANT_APPLICANT_CAPABILITY_CODES` en `config/tenantApplicantCapability.js` en lugar de a un grupo concreto.

### 3. Aplicar el seed

```sh
# Con docker compose (recomendado)
cd TC3005B.501-Backend
bun run docker:dev:down
bun run docker:dev
# El migrate service re-corre `node prisma/seed.js` (idempotente) en cada up.

# O, si ya tienes el backend corriendo nativo:
node prisma/seed.js
```

**No necesitas un `docker:dev:clean`** (que borra datos). El catálogo se aplica vía `upsert` y los join-tables vía `createMany({skipDuplicates:true})` — seguro de correr repetidamente.

### 4. Proteger la ruta backend

En tu archivo de rutas (`TC3005B.501-Backend/routes/*.js`):

```js
import { requirePermission, requireAnyPermission } from "../middleware/permissionMiddleware.js";

// AND — requiere TODOS los códigos listados
router.route("/export-expenses")
  .get(generalRateLimiter, ...requirePermission("expense:export"), handler);

// OR — requiere AL MENOS UNO
router.route("/some-endpoint")
  .get(...requireAnyPermission("travel_request:view_own", "travel_request:view_any"), handler);
```

**Nunca uses `authorizePermission` directamente**. Siempre `requirePermission` / `requireAnyPermission`, que componen `authenticateToken` como primer middleware — así es imposible introducir una ruta sin autenticación.

### 5. Exponer condicionalmente en el frontend

Los permisos efectivos del usuario se cargan en `sessionStorage` la primera vez que cualquier componente llama a `getCachedPermissions()`. El login también los devuelve directamente en el body para poder pre-cargar el store.

```tsx
import { hasPermission } from "@utils/permissions";
import { getCachedPermissions } from "@stores/permissionStore";

const perms = await getCachedPermissions();
if (hasPermission(perms, "expense:export")) {
  // renderiza el botón
}
```

Para decidir **si una pantalla entera existe** para un rol, usa `src/config/routeAccess.ts` (por rol) como hasta ahora; las rutas siguen siendo gated por rol a nivel middleware de Astro. Los permisos granulares son para condicionar acciones **dentro** de una pantalla.

### 6. Agregar test E2E

En `TC3005B.501-Frontend/cypress/e2e/permissions.cy.ts`, agrega un caso al bloque de "Role → effective permission resolution" verificando que el rol esperado incluye el nuevo código. Para grants/revokes de usuario, sigue el patrón del bloque "Direct user grant (additive over role)".

---

## Endpoints admin para gestionar permisos en caliente

Todos bajo `/api/admin/*`, todos requieren permisos meta (`permission:read`, `permission:write`, `permission_group:manage`, `role:manage_permissions`, `user:manage_permissions`). Ver [`routes/permissionRoutes.js`](../../../TC3005B.501-Backend/routes/permissionRoutes.js).

### Catálogo
| Método | Ruta | Permiso |
|---|---|---|
| GET    | `/api/admin/permissions` | `permission:read` |
| POST   | `/api/admin/permissions` | `permission:write` |
| PATCH  | `/api/admin/permissions/:id` | `permission:write` |
| DELETE | `/api/admin/permissions/:id` (soft delete → `active=false`) | `permission:write` |

### Grupos
| Método | Ruta | Permiso |
|---|---|---|
| GET    | `/api/admin/permission-groups` | `permission:read` |
| POST   | `/api/admin/permission-groups` | `permission_group:manage` |
| PATCH  | `/api/admin/permission-groups/:id` | `permission_group:manage` |
| DELETE | `/api/admin/permission-groups/:id` | `permission_group:manage` |
| POST   | `/api/admin/permission-groups/:id/permissions` — body `{ permissionIds: number[] }` | `permission_group:manage` |
| DELETE | `/api/admin/permission-groups/:id/permissions/:permissionId` | `permission_group:manage` |

### Asignación a un rol
| Método | Ruta | Permiso |
|---|---|---|
| POST   | `/api/admin/roles/:roleId/permissions` | `role:manage_permissions` |
| DELETE | `/api/admin/roles/:roleId/permissions/:permissionId` | `role:manage_permissions` |
| POST   | `/api/admin/roles/:roleId/permission-groups` | `role:manage_permissions` |
| DELETE | `/api/admin/roles/:roleId/permission-groups/:groupId` | `role:manage_permissions` |

### Asignación directa a un usuario (aditivo)
| Método | Ruta | Permiso |
|---|---|---|
| POST   | `/api/admin/users/:userId/permissions` | `user:manage_permissions` |
| DELETE | `/api/admin/users/:userId/permissions/:permissionId` | `user:manage_permissions` |
| POST   | `/api/admin/users/:userId/permission-groups` | `user:manage_permissions` |
| DELETE | `/api/admin/users/:userId/permission-groups/:groupId` | `user:manage_permissions` |
| GET    | `/api/admin/users/:userId/effective-permissions` | `permission:read` |

### Endpoint self-service (cualquier usuario autenticado)

```
GET /api/user/me/permissions
→ { userId, role, permissions: string[] }
```

---

## Seed y Docker — flujo para nuevos colaboradores

Cuando alguien clona el repo por primera vez o agrega un permiso:

1. **Primer clone**
   ```sh
   cd TC3005B.501-Backend
   bun install
   bun run docker:dev          # postgres + localstack + s3-init + migrate + backend
   ```
   El `migrate` service hace `bun install` → `prisma generate` → `prisma db push` → **seed completo** (referencia + dummy). Crea un sentinel `/app/node_modules/.seeded` dentro del volumen para no re-insertar los dummy data.

2. **Un compañero agrega un permiso nuevo (ejemplo: `expense:export`)**
   - Modifica `prisma/seed.js` como en la sección anterior.
   - Hace commit y push.

3. **Tú haces `git pull`** — tienes dos opciones:
   - **Con el stack corriendo** (más rápido, no reinicia nada):
     ```sh
     bun run docker:permissions:sync
     ```
     Ejecuta `node prisma/seed.js` (solo referencia, idempotente) dentro del contenedor backend. Los permisos nuevos aparecen en segundos sin perder datos dummy.
   - **Con el stack apagado**:
     ```sh
     bun run docker:dev:down
     bun run docker:dev
     ```
     El migrate service detecta el sentinel existente y corre **solo la seed de referencia** automáticamente. También idempotente; datos dummy intactos.

### Scripts de reset (cuadro comparativo)

| Comando | Qué hace | Cuándo usarlo | Datos que se pierden |
|---|---|---|---|
| `bun run docker:permissions:sync` | Corre `node prisma/seed.js` dentro del contenedor backend en caliente. Solo aplica la sección de referencia (roles, statuses, **permisos**). Idempotente. | Un compañero agregó un permiso y hiciste `git pull` — quieres que aparezca sin reiniciar nada. | Ninguno. |
| `bun run docker:data:reset` | Dentro del contenedor backend: `bunx prisma db push --force-reset && node prisma/seed.js dev`. **Tira todas las tablas** de Postgres y re-aplica el schema + seed completo. No toca LocalStack (S3). | Datos dummy corruptos, migraciones raras entre ramas, tests E2E contaminaron el estado. | Todo lo que esté en Postgres (requests, usuarios creados a mano, grants directos, comprobantes registrados). Mantiene los archivos en S3 (LocalStack). |
| `bun run docker:dev:clean` | `docker compose down -v` — **borra todos los volúmenes** del proyecto: `pgdata`, `localstack_data`, `node_modules_dev`, `certs`. | Algo se rompió a nivel docker (certs corruptos, deps medio instaladas, sentinel en mal estado), quieres un "fresh install" completo. | Todo: DB relacional + objetos en S3 local + deps instaladas + certs HTTPS. |
| `bun run docker:dev:down` | Apaga contenedores, deja volúmenes. | Pausar el trabajo del día. | Nada. |

**Orden sugerido cuando algo no funciona**:
1. `docker:permissions:sync` si parece solo desfase de catálogo.
2. `docker:data:reset` si es problema de datos.
3. `docker:dev:clean && docker:dev` si nada de lo anterior arregla.

### Caso real — `Pedro Castillo` fantasma

Durante el desarrollo del sistema de permisos se detectó que la DB tenía un usuario `Pedro Castillo (user_id=1)` inyectado por una versión previa del seed. Los nuevos seeds no lo crean, pero `user_id=1` ya estaba ocupado. Consecuencia: las solicitudes dummy (que referencian `user_id=1`) pertenecían a ese fantasma y no al `andres.gomez` con el que los tests de Cypress hacen login → dashboard vacío → tests fallan.

Esto aparece cuando el **sentinel `.seeded` sigue activo desde una versión anterior del código**. Solución definitiva:

```sh
bun run docker:dev:clean && bun run docker:dev
```

Como regla: si cambias la definición de los usuarios dummy o su orden de inserción, avísale al equipo para que corran `docker:dev:clean`.

### Desarrollo nativo (sin docker para backend)

Si prefieres correr el backend con `bun run dev` directo en el host, la DB sigue viviendo en docker:

```sh
# Una sola vez: levanta solo postgres + localstack
cd TC3005B.501-Backend
docker compose -f docker-compose.dev.yml up -d postgres localstack
# Ajusta tu .env local para apuntar a puerto 5434 (postgres host-side)
DATABASE_URL="postgresql://cocoscheme:cocoscheme_dev@localhost:5434/CocoScheme?schema=public"
# Seed + dev
bun run dummy_db                # o `bun run empty_db` si no quieres dummy data
bun run dev
```

---

## Middleware — resumen de defensa en profundidad

`middleware/permissionMiddleware.js` expone los helpers:

```js
requirePermission("codigo1", "codigo2")     // AND — todos requeridos
requireAnyPermission("codigo1", "codigo2")  // OR  — al menos uno
```

Cada uno retorna un **array** `[authenticateToken, tenantContextMiddleware, applyRlsForRequest, loadPermissions, authorizePermission(...)]` (para `requireAnyPermission`, el último hop es `authorizeAnyPermission(...)`), usado con spread:

```js
router.get("/foo", ...requirePermission("foo:read"), handler);
```

Propiedades garantizadas:

1. **`authenticateToken` siempre corre primero.** No hay forma de llegar a `authorizePermission` sin JWT válido.
2. **`tenantContextMiddleware` + `applyRlsForRequest` fijan el contexto de tenant antes de resolver permisos.** Establecen el `organization_id` de la request y aplican la Row-Level Security de Postgres, de modo que la resolución de permisos y todas las consultas posteriores quedan acotadas a la organización correcta.
3. **`loadPermissions` es idempotente por request.** Si varios middlewares requieren permisos en la misma ruta, se consulta la DB una sola vez (se cachea en `req.user.permissionSet`).
4. **`authorizePermission` falla con 403 si `req.user` o `permissionSet` no existen** — defensa contra casos de mal uso, nunca deja pasar silenciosamente.
5. **Los errores 401/403 usan las clases en `authErrors.js`** — formato de respuesta consistente.

El `requireAuth(roles)` legacy en `authMiddleware.js` **se conserva** y sigue funcionando para código que no se ha migrado o que prefiere cheque por rol. No está deprecado; simplemente hay ahora una opción más granular.

---

## Testing

- **Unit (Jest)**: [`tests/middleware/permissionMiddleware.test.js`](../../../TC3005B.501-Backend/tests/middleware/permissionMiddleware.test.js) — verifica AND/OR, idempotencia de `loadPermissions`, composición con `authenticateToken`, manejo de `req.user` ausente.
- **E2E (Cypress)**: [`cypress/e2e/permissions.cy.ts`](../../../TC3005B.501-Frontend/cypress/e2e/permissions.cy.ts) — corre contra el stack docker, verifica: resolución por rol para los 6 roles operativos con login en Cypress (Solicitante, Agencia de viajes, Cuentas por pagar, N1, N2, Administrador; el bootstrap siembra además `Observador`), 401 sin token, 403 sin permiso, CRUD de catálogo, grant/revoke directo a usuario, CRUD de grupos con asignación. Usa `cy.apiLogin(...)` y `cy.apiAs(session, {...})` (en [`cypress/support/commands.ts`](../../../TC3005B.501-Frontend/cypress/support/commands.ts)) que manejan JWT + CSRF automáticamente.

Ejecutar E2E:

```sh
# backend corriendo (docker o native)
# frontend corriendo en :4321 (necesario por cypress baseUrl)
cd TC3005B.501-Frontend
bunx cypress run --spec "cypress/e2e/permissions.cy.ts"
```

---

## Nomenclatura

| Término | Significado |
|---------|-------------|
| **AND / OR** | Semántica de `requirePermission` (todos los códigos) vs `requireAnyPermission` (al menos uno). |
| **CSRF** | Cross-Site Request Forgery — token en mutaciones; ver `GET /api/user/csrf-token`. |
| **E2E** | End-to-End — prueba de extremo a extremo (Cypress contra stack Docker). |
| **JWT** | JSON Web Token — credencial de sesión en cookie httpOnly o header Bearer. |
| **RBAC** | Role-Based Access Control — control de acceso basado en roles; permisos atómicos unidos a roles, grupos y usuarios. |
| **RLS** | Row-Level Security — políticas PostgreSQL que limitan filas por `organization_id`. |
| **TL;DR** | Too Long; Didn't Read — resumen rápido al inicio del documento. |
