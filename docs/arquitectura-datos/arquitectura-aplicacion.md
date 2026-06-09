# Arquitectura de Aplicación — Frontend, Backend y Permisos

| Metadato | Valor |
|----------|--------|
| **Versión del documento** | 1.1.0 |
| **Última actualización** | 2026-06-09 |
| **Referencias** | [app.js](../../../TC3005B.501-Backend/app.js), [middleware.ts](../../../TC3005B.501-Frontend/src/middleware.ts), [apiClient.ts](../../../TC3005B.501-Frontend/src/utils/apiClient.ts), [permissionMiddleware.js](../../../TC3005B.501-Backend/middleware/permissionMiddleware.js), [permissionService.js](../../../TC3005B.501-Backend/services/permissionService.js), [approverResolver.js](../../../TC3005B.501-Backend/services/approverResolver.js), [employeeHierarchyService.js](../../../TC3005B.501-Backend/services/employeeHierarchyService.js), [schema.prisma](../../../TC3005B.501-Backend/prisma/schema.prisma), [diagramas-c4.md](diagramas-c4.md) (C4 Level 3) |

## Índice

0. [Stack tecnológico general](#0-stack-tecnológico-general)
1. [Capas del backend](#1-capas-del-backend)
2. [Capas del frontend](#2-capas-del-frontend)
3. [Sistema de permisos](#3-sistema-de-permisos)
4. [Jerarquía de aprobación en runtime](#4-jerarquía-de-aprobación-en-runtime)
5. [Relación con otros documentos](#5-relación-con-otros-documentos)

---

## 0. Stack tecnológico general

Vista de conjunto del ecosistema CocoScheme: el navegador consume el frontend Astro SSR, que a su vez llama a CocoAPI (Express); el backend persiste en PostgreSQL y S3 e integra servicios externos.

```mermaid
flowchart TB
  subgraph client [Cliente]
    Browser[Navegador HTTPS]
  end
  subgraph fe [Frontend Astro SSR]
    AstroPages[pages y views]
    ReactIslands[React islands]
    ApiClient[apiClient.ts]
  end
  subgraph be [Backend Express]
    Routes[routes y controllers]
    Services[services]
    Prisma[Prisma Client]
  end
  subgraph data [Datos]
    PG[(PostgreSQL 16)]
    S3[(AWS S3)]
  end
  subgraph ext [Externos]
    SAT[SAT SOAP]
    BMX[Banxico]
    Duffel[Duffel]
    SMTP[SMTP]
    Push[Web Push]
  end
  Browser --> AstroPages
  AstroPages --> ReactIslands
  ReactIslands --> ApiClient
  ApiClient -->|HTTPS JSON JWT CSRF| Routes
  Routes --> Services --> Prisma --> PG
  Services --> S3
  Services --> SAT
  Services --> BMX
  Services --> Duffel
  Services --> SMTP
  Services --> Push
```

| Componente | Tecnología | Versión |
|------------|------------|---------|
| Frontend | Astro + React + Tailwind | 5.7 · 19 · 4.1 |
| Runtime | Node.js | 22 |
| Backend | Express | 4.18 |
| ORM | Prisma | 6.16 |
| Base relacional | PostgreSQL | 16 |
| Almacenamiento binario | AWS S3 (SSE-S3, pre-signed) | — |

Detalle por capa: [sección 1](#1-capas-del-backend) (backend) y [sección 2](#2-capas-del-frontend) (frontend).

---

## 1. Capas del backend

La **CocoAPI** es una aplicación **Express.js** que sigue una arquitectura en capas: petición → middleware → rutas → servicios → modelos → base de datos.

```mermaid
flowchart TD
    subgraph cliente [Cliente]
        FE[Frontend Astro SSR ver sección 2]
    end

    subgraph express [CocoAPI Express]
        direction TB
        MW1[CORS + cookieParser + httpLogger]
        MW2[CSRF Protection]
        MW3[authenticateToken JWT]
        MW4[tenantContextMiddleware org_id]
        MW5[applyRlsForRequest RLS PG]
        MW6[loadPermissions + authorizePermission]

        subgraph rutas [Rutas API]
            R1["/api/applicant"]
            R2["/api/authorizer"]
            R3["/api/solicitudes"]
            R4["/api/user"]
            R5["/api/admin"]
            R6["/api/travel-agent"]
            R7["/api/accounts-payable"]
            R8["/api/files"]
            R9["/api/comprobantes"]
            R10["/api/notifications"]
            R11["/api/organizations"]
            R12["policies, refunds, export, ..."]
        end

        subgraph servicios [Servicios]
            S1[permissionService]
            S2[approverResolver]
            S3[employeeHierarchyService]
            S4[applicantService / authorizerService]
            S5[solicitudJourneyService / workflowRulesEngine]
            S6[fileStorage / receiptFileService]
            S7[notificationService / webPushService]
            S8[organizationService / userService]
        end

        subgraph modelos [Modelos / ORM]
            M1[permissionModel]
            M2[authorizerModel]
            M3[Prisma Client]
        end
    end

    subgraph storage [Almacenamiento]
        PG[(PostgreSQL CocoScheme)]
        OBJ[(AWS S3)]
    end

    FE -->|HTTPS JSON + cookie token| MW1
    MW1 --> MW2 --> MW3 --> MW4 --> MW5 --> MW6
    MW6 --> rutas
    rutas --> servicios
    servicios --> modelos
    M3 -->|Prisma ORM| PG
    M3 -->|S3 key en Receipt| OBJ
```

### Tabla de módulos de ruta

| Prefijo | Módulo de ruta | Propósito principal |
|---------|----------------|---------------------|
| `/api/applicant` | `applicantRoutes` | Solicitudes, rutas de viaje, perfil |
| `/api/authorizer` | `authorizerRoutes` | Aprobación N1/N2, alertas |
| `/api/solicitudes` | `solicitudWorkflowRoutes`, `inboxRoutes`, `requestCommentRoutes` | Flujo unificado de solicitud (inbox, aprobar/rechazar, comentarios) |
| `/api/approval-substitutes` | `approvalSubstituteRoutes` | Sustitutos de aprobación durante ausencias |
| `/api/user` | `userRoutes` | Login, sesión, perfil, CSRF token |
| `/api/admin` | `adminRoutes`, `permissionRoutes` | Gestión de usuarios, roles y permisos |
| `/api/travel-agent` | `travelAgentRoutes` | Atención de solicitudes por agencia |
| `/api/accounts-payable` | `accountsPayableRoutes` | Cotización y validación de comprobantes |
| `/api/files` | `fileRoutes` | Carga PDF/XML → AWS S3 (pre-signed URLs) |
| `/api/comprobantes` | `comprobantesRoutes` | CFDI (`cfdi_comprobantes`) |
| `/api/notifications` | `notificationRoutes` | Push notifications, inbox de alertas |
| `/api/organizations` | `organizationRoutes` | Multi-tenant: gestión de organizaciones |
| `/api/policies` | `policyRoutes`, `employeeCategoryRouter` | Política de reembolsos y categorías |
| `/api/refunds` | `refundRoutes` | Motor de reglas de reembolso |
| `/api/export` | `exportRoutes` | Exportación contable al ERP (pólizas) |
| `/api/reports` | `reportRoutes` | Reportes gerenciales |
| `/api/workflow-rules` | `workflowRuleRoutes` | CRUD de reglas de flujo por departamento |
| `/api/viaticos-policy` | `viaticasPolicyRoutes` | Topes de hotel y comida por org |
| `/api/keys` / `/api/external` | `apiKeyRoutes`, `externalApiKeyRoutes` | API Keys para integraciones ERP |
| `/api/onboarding/import` | `onboardingImportRoutes` | Importación masiva de usuarios (CSV/JSON) |

---

## 2. Capas del frontend

El frontend **CocoScheme** usa **Astro 5.7** con adaptador Node (SSR) e islas **React 19**. La petición del usuario atraviesa middleware de Astro, páginas/vistas, componentes interactivos y el cliente HTTP centralizado antes de llegar a CocoAPI.

| Capa | Archivos / carpetas | Responsabilidad |
|------|---------------------|-----------------|
| Entrada SSR | `src/pages/*.astro`, `src/views/*.astro` | Rutas HTML, layout, hidratación de islas |
| Middleware Astro | `src/middleware.ts` | Sesión por cookie `role`/`token`; whitelist en `src/config/routeAccess.ts` |
| UI interactiva | `src/components/*.tsx`, `src/views/admin/*.tsx` | Formularios, bandejas, modales |
| Validación | react-hook-form + Zod | Esquemas de formulario en cliente |
| Cliente HTTP | `src/utils/apiClient.ts` | JWT (cookie), CSRF, header `X-Organization-Id` |
| Destino | CocoAPI `/api/*` | Autorización fina en backend (sección 3.3) |

```mermaid
flowchart TD
    subgraph browser [Navegador]
        User[Usuario]
    end
    subgraph astro [CocoScheme Frontend Astro SSR]
        MW[middleware.ts auth y routeAccess]
        Pages[pages y views .astro]
        Islands[React islands .tsx]
        Forms[react-hook-form + Zod]
        Client[apiClient.ts]
    end
    subgraph api [CocoAPI]
        BE[Express routes]
    end
    User -->|HTTPS| MW
    MW --> Pages
    Pages --> Islands
    Islands --> Forms
    Islands --> Client
    Client -->|JWT cookie CSRF org header| BE
```

> **Nota:** el frontend restringe **rutas por rol** (`roleRoutes` en `routeAccess.ts`). Los permisos atómicos (`resource:action`) se evalúan en el backend mediante `requirePermission` (sección 3.3).

---

## 3. Sistema de permisos

### 3.1 Modelo de datos (RBAC)

El sistema usa **RBAC** (control de acceso basado en roles) **granular por organización**. El catálogo de `Permission` es global; los grupos y asignaciones son per-org.

```mermaid
erDiagram
    Permission {
        int permission_id PK
        string code UK
        string resource
        string action
        bool active
    }

    PermissionGroup {
        int group_id PK
        string group_name
        bool active
    }

    PermissionGroupItem {
        int group_id FK
        int permission_id FK
    }

    Role {
        int role_id PK
        bigint organization_id FK
        string role_name
        float max_approval_amount
        bool is_system
    }

    RolePermission {
        int role_id FK
        int permission_id FK
    }

    RolePermissionGroup {
        int role_id FK
        int group_id FK
    }

    User {
        int user_id PK
        int role_id FK
        bigint organization_id FK
        bool active
    }

    UserPermission {
        int user_id FK
        int permission_id FK
    }

    UserPermissionGroup {
        int user_id FK
        int group_id FK
    }

    Permission ||--o{ PermissionGroupItem : member
    PermissionGroup ||--o{ PermissionGroupItem : contains
    Role ||--o{ RolePermission : direct_grant
    Role ||--o{ RolePermissionGroup : group_grant
    RolePermission }o--|| Permission : grants
    RolePermissionGroup }o--|| PermissionGroup : includes
    User ||--o{ UserPermission : override_grant
    User ||--o{ UserPermissionGroup : override_group
    UserPermission }o--|| Permission : grants
    UserPermissionGroup }o--|| PermissionGroup : includes
    User }o--|| Role : assigned
```

### 3.2 Resolución de permisos efectivos en runtime

Al inicio de cada petición autenticada, `loadEffectivePermissions(userId)` computa el **conjunto efectivo** de códigos de permiso del usuario mediante la siguiente unión:

```
permisos_efectivos =
    role.rolePermissions (directos activos)
  ∪ role.rolePermissionGroups[*].items (grupo activo, permiso activo)
  ∪ user.userPermissions (directos activos)
  ∪ user.userPermissionGroups[*].items (grupo activo, permiso activo)
  ∪ TENANT_APPLICANT_CAPABILITY_CODES (si org.kind y user.active lo permiten)
```

El resultado se guarda en `req.user.permissionSet` (un `Set<string>`) y es **idempotente** dentro de la misma petición.

```mermaid
flowchart LR
    A[loadEffectivePermissions userId] --> B{user activo?}
    B -- no --> Z[return vacío]
    B -- sí --> C[role.rolePermissions activos]
    C --> D[role.rolePermissionGroups → items activos]
    D --> E[user.userPermissions activos]
    E --> F[user.userPermissionGroups → items activos]
    F --> G{¿tenant applicant\ncapability aplica?}
    G -- sí --> H[agregar TENANT_APPLICANT_CAPABILITY_CODES]
    G -- no --> I[Set deduplicado de códigos]
    H --> I
    I --> J[req.user.permissionSet]
```

### 3.3 Cadena de middleware de autorización

Las rutas protegidas usan `requirePermission(...codes)` o `requireAnyPermission(...codes)`. Ambos helpers encadenan los mismos cinco pasos; solo difieren en el paso final (AND vs OR).

```mermaid
flowchart TD
    Entry["requirePermission(...codes)\no requireAnyPermission(...codes)"]
    M1["1 authenticateToken\nJWT Bearer o cookie → req.user"]
    M2["2 tenantContextMiddleware\norganizationId → req.tenantContext"]
    M3["3 applyRlsForRequest\nSET LOCAL app.current_organization_id"]
    M4["4 loadPermissions\nloadEffectivePermissions → permissionSet"]
    M5["5a authorizePermission\nAND — todos los códigos"]
    M5b["5b authorizeAnyPermission\nOR — al menos un código"]
    Handler[Controlador de ruta]
    Entry --> M1 --> M2 --> M3 --> M4
    M4 --> M5 --> Handler
    M4 --> M5b --> Handler
```

Ejemplo: `requirePermission("solicitud:create")` exige que `solicitud:create` esté en `req.user.permissionSet` tras los pasos 1–4.

| Helper | Semántica | Paso 5 | Uso típico |
|--------|-----------|--------|------------|
| `requirePermission(...codes)` | AND — todos los códigos requeridos | `authorizePermission` | Operaciones específicas de un solo recurso |
| `requireAnyPermission(...codes)` | OR — al menos un código | `authorizeAnyPermission` | Rutas accesibles por varios roles |

Fuente del orden: [`permissionMiddleware.js`](../../../TC3005B.501-Backend/middleware/permissionMiddleware.js).

### 3.4 Roles de sistema vs. roles personalizados

| Atributo | Rol de sistema (`isSystem: true`) | Rol personalizado |
|----------|-----------------------------------|-------------------|
| Nombre | Inmutable | Editable (2–40 chars) |
| Permisos | Solo via grupos predefinidos; no editables desde API | CRUD completo desde admin |
| `maxApprovalAmount` | Editable | Editable |
| Eliminar | Bloqueado | Permitido si sin usuarios activos |

El campo `Role.maxApprovalAmount` define el **tope de monto** (`requested_fee`) que el rol puede aprobar en un paso de autorización.

---

## 4. Jerarquía de aprobación en runtime

### 4.1 Estructura: adjacency list en `User`

La jerarquía organizacional se almacena como una **adjacency list** en la tabla `User`:

```
User.managerUserId → User.userId (auto-referencia)
```

Cada usuario apunta a su **jefe directo**. La cadena de aprobación se recorre hacia arriba en tiempo de ejecución, sin materializar la jerarquía completa en base de datos.

```mermaid
erDiagram
    User {
        int user_id PK
        int manager_user_id FK
        int role_id FK
    }
    User ||--o{ User : "manager →"
```

### 4.2 Resolución de aprobadores N1/N2 (`approverResolver.js`)

Cuando un solicitante envía una solicitud, `resolveN1N2Approvers` determina quiénes serán N1 y N2:

```mermaid
flowchart TD
    Start[resolveN1N2Approvers\norganizationId, departmentId, userId]
    Start --> Walk[Recorrer cadena managerUserId\nhasta 10 niveles]
    Walk --> Check{¿approverIds\n≥ 2?}

    Check -- sí --> Assign[n1 = approverIds 0\nn2 = approverIds 1]

    Check -- no --> Fallback[Buscar por rol N1 / N2\npreferencia mismo departamento]
    Fallback --> Fill[completar approverIds\ncon fallbacks]
    Fill --> Assign

    Assign --> Return[return n1UserId, n2UserId, approverIds]
```

**Reglas de fallback:**
1. Se recorre `managerUserId` hasta 10 niveles; cada nivel es un aprobador potencial.
2. Si la cadena tiene menos de 2 nodos, se completa con el primer usuario activo de rol `"N1"` / `"N2"` en la organización, priorizando el mismo departamento del solicitante.
3. Se garantiza que `approverIds` siempre tenga al menos los IDs de N1 y N2 finales.

### 4.3 Utilidades de jerarquía (`employeeHierarchyService.js`)

| Función | Descripción | Límite |
|---------|-------------|--------|
| `getApprovalChain(userId, maxDepth=8)` | Cadena de aprobación ascendente (jefe, jefe del jefe, …). Lanza `409` si detecta ciclo. | 8 niveles |
| `getSubordinatesRecursive(managerUserId, maxNodes=2000)` | Subordinados transitivos (BFS). | 2 000 nodos |
| `getHierarchyDepth(userId, maxDepth=8)` | Profundidad de la cadena de aprobación disponible. | 8 niveles |
| `wouldCreateManagerCycle(userId, proposedManagerUserId)` | Detecta si asignar un jefe crearía un ciclo antes de guardar. | 32 niveles |

### 4.4 Secuencia de resolución al crear una solicitud

```mermaid
sequenceDiagram
    participant Sol as Solicitante
    participant API as CocoAPI
    participant DB as PostgreSQL

    Sol->>API: POST /api/solicitudes (enviar solicitud)
    API->>DB: SELECT managerUserId WHERE userId = solicitante
    DB-->>API: managerId (N1 candidato)
    API->>DB: SELECT managerUserId WHERE userId = managerId
    DB-->>API: managerId2 (N2 candidato) o null
    alt cadena incompleta (< 2 nodos)
        API->>DB: SELECT userId WHERE role.roleName = 'N1'\nAND organizationId = org\nAND departmentId = dept (preferencia)
        DB-->>API: fallbackN1
        API->>DB: SELECT userId WHERE role.roleName = 'N2'\nAND organizationId = org
        DB-->>API: fallbackN2
    end
    API->>DB: UPDATE Request SET n1_user_id, n2_user_id, status = 'Primera Revisión'
    API-->>Sol: 200 OK
```

---

## 5. Relación con otros documentos

| Documento | Qué complementa |
|-----------|-----------------|
| [Modelo ER](modelo-er.md) | Tablas `Permission`, `PermissionGroup`, `Role`, `User` (con `manager_user_id`) |
| [Flujos y pantallas](flujos.md) | Capas del sistema, rutas REST, estados de solicitud |
| [Flujos de pantallas por rol](../guias-usuario/flujos-pantallas-por-rol.md) | Qué pantallas son accesibles por rol en el frontend |
| [Documento de Arquitectura](documento-arquitectura.md) | Vista unificada negocio, datos, infra, RNF |

> **Nota:** La lógica de adjacency list (`managerUserId`) está documentada también en el modelo Prisma `User` (`schema.prisma`, campo `manager_user_id`). `approverResolver.js` y `employeeHierarchyService.js` son los únicos consumidores en runtime.

---

## Nomenclatura

| Término | Significado |
|---------|-------------|
| **API** | Application Programming Interface — endpoints HTTP `/api/*` de CocoAPI. |
| **BFS** | Breadth-First Search — recorrido en anchura usado para subordinados transitivos. |
| **JWT** | JSON Web Token — token de sesión verificado en `authenticateToken`. |
| **N1 / N2** | Autorizador de primer y segundo nivel en la cadena de aprobación. |
| **ORM** | Object-Relational Mapping — capa Prisma entre servicios y PostgreSQL. |
| **RBAC** | Role-Based Access Control — permisos atómicos (`resource:action`) unidos por roles, grupos y asignación directa a usuario. |
| **RLS** | Row-Level Security — filtrado de filas en PostgreSQL por organización activa. |
| **REST** | Representational State Transfer — API HTTP JSON consumida por el frontend. |
| **SSR** | Server-Side Rendering — Astro renderiza HTML en Node antes de hidratar islas React. |
