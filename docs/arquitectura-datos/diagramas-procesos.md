# Diagramas de Procesos

> **Versión:** 1.0
> **Fecha:** 2026-06-10
> **Responsables:** Equipo CoCo Consulting 2
> **Stack:** PostgreSQL / Prisma — sin triggers MariaDB

Este documento contiene 10 diagramas Mermaid que detallan los macro-procesos del sistema CocoAPI.
Cada diagrama usa nombres reales de servicios y archivos del código fuente.

---

## Índice

1. [Onboarding completo](#1-onboarding-completo)
2. [Solicitud de viaje — máquina de estados](#2-solicitud-de-viaje--máquina-de-estados)
3. [Aprobación configurable](#3-aprobación-configurable)
4. [Logística del viaje](#4-logística-del-viaje)
5. [Comprobación de gastos](#5-comprobación-de-gastos)
6. [Cierre y reembolso](#6-cierre-y-reembolso)
7. [Validación CFDI ante SAT](#7-validación-cfdi-ante-sat)
8. [Políticas y excepciones de reembolso](#8-políticas-y-excepciones-de-reembolso)
9. [Workflow dinámico con escalamiento](#9-workflow-dinámico-con-escalamiento)
10. [Multi-tenant onboarding](#10-multi-tenant-onboarding)

---

## 1. Onboarding completo

Admin Ditta crea la organización, `bootstrapOrganization` siembra catálogos y roles por defecto,
el admin de la organización importa usuarios vía CSV/JSON con `onboardingImportService` (preview + apply),
y el tenant extension queda activo para aislar datos.

```mermaid
flowchart TD
    A[Admin Ditta] -->|POST /api/organizations| B[organizationRoutes.js]
    B --> C[organizationService.create]
    C --> D[PostgreSQL: INSERT Organization]
    D --> E[bootstrapOrganization.js]
    E --> E1[Sembrar alert_messages x7]
    E --> E2[Sembrar receipt_types x7]
    E --> E3[Sembrar permission_groups x8]
    E --> E4[Sembrar roles x7]
    E --> E5[Sembrar notification_templates x4]
    E --> E6[Sembrar chart_of_accounts]
    E --> E7[ensureOrganizationAdmin]

    E7 --> F[Org lista para uso]
    F --> G[Admin Org]
    G -->|POST /api/onboarding-import/preview| H[onboardingImportService.previewImport]
    H --> H1{CSV o JSON?}
    H1 -->|CSV| H2[Parsear CSV]
    H1 -->|JSON| H3[Parsear JSON]
    H2 --> H4[Validar usuarios + inferir roles por jerarquía]
    H3 --> H4
    H4 --> H5[Retornar preview token + resumen]

    H5 --> I[Admin Org revisa preview]
    I -->|POST /api/onboarding-import/apply| J[onboardingImportService.applyImport]
    J --> J1[Verificar token TTL 10min]
    J1 --> J2[Resolver role mappings + custom roles]
    J2 --> J3[Crear users + employees + manager links]
    J3 --> J4[tenantExtension auto-scope activo]
    J4 --> K[Usuarios operativos con tenant isolation]
```

---

## 2. Solicitud de viaje — máquina de estados

Máquina de 10 estados con transiciones controladas. El motor de reglas (`workflowRulesEngine`) puede
saltar niveles de aprobación. Cada transición dispara triggers Prisma (`prisma/middleware.js`).

> Referencia: [Service Blueprint — Máquina de estados](service-blueprint.md#7-máquina-de-estados-de-la-solicitud)

```mermaid
stateDiagram-v2
    [*] --> Borrador : P12 crear draft

    Borrador --> PrimeraRevision : P13 confirmar → workflowRulesEngine\ninitialStatusFromLevels = 2
    Borrador --> SegundaRevision : P13 confirmar → workflowRulesEngine\ninitialStatusFromLevels = 3
    Borrador --> Cancelado : P11 cancelar

    PrimeraRevision --> SegundaRevision : P42 aprobar N1 → statusAfterN1Approval\nhay N2
    PrimeraRevision --> CotizacionViaje : P42 aprobar N1 → statusAfterN1Approval\nsin N2
    PrimeraRevision --> Rechazado : P43 rechazar
    PrimeraRevision --> Cancelado : P11 cancelar
    PrimeraRevision --> SegundaRevision : P165 escalationJob\n48h timeout → status=3

    SegundaRevision --> CotizacionViaje : P42 aprobar N2 → statusAfterN2Approval
    SegundaRevision --> Rechazado : P43 rechazar
    SegundaRevision --> Cancelado : P11 cancelar

    CotizacionViaje --> AtencionAgencia : P24 CxP cotiza\nrequiere hotel/vuelo
    CotizacionViaje --> ComprobacionGastos : P24 CxP cotiza\nsin agencia
    CotizacionViaje --> Cancelado : P11 cancelar

    AtencionAgencia --> ComprobacionGastos : P23 agencia atiende
    AtencionAgencia --> Cancelado : P11 cancelar

    ComprobacionGastos --> ValidacionComprobantes : P18 enviar comprobantes

    ValidacionComprobantes --> Finalizado : P25/P26 todos aprobados
    ValidacionComprobantes --> ComprobacionGastos : P26 alguno rechazado

    state "Triggers Prisma en cada transición" as triggers {
        [*] --> P36_DeactivateRequest : status=9|10 → active=false
        [*] --> P38_ManageAlert : auto-crea/actualiza/elimina alertas
        [*] --> P41_Notification : workflowNotificationService.dispatchToUser
    }

    Cancelado --> [*]
    Rechazado --> [*]
    Finalizado --> [*]
```

---

## 3. Aprobación configurable

El motor de reglas de workflow evalúa las reglas configuradas por el admin, el resolver
determina N1/N2, los sustitutos temporales se aplican, y el cron de escalamiento actúa en caso de timeout.

```mermaid
sequenceDiagram
    participant S as Solicitante
    participant API as solicitudWorkflowRoutes.js
    participant WRE as workflowRulesEngine.js
    participant AR as approverResolver.js
    participant AS as approvalSubstituteRoutes.js
    participant DB as PostgreSQL
    participant CRON as escalationJob (hourly)
    participant WNS as workflowNotificationService.js
    participant H as SolicitudHistorial

    S->>API: POST /:id/aprobar o /rechazar
    API->>WRE: computeLevelsFromRules(rules, ctx)
    WRE->>WRE: ruleMatches(rule, ctx)
    WRE->>WRE: maxLevelFromImporteBands(amount, rules)
    WRE-->>API: { levels, maxApprovalLevel, skipApplied }

    API->>AR: resolveN1N2Approvers(db, orgId, deptId, userId)
    AR->>DB: Query manager chain (hasta 10 niveles)
    AR->>AR: Estrategia 1: Manager chain
    AR->>AR: Estrategia 2: Dept preference
    AR->>AR: Estrategia 3: Org-wide fallback
    AR-->>API: { n1UserId, n2UserId, approverIds[] }

    API->>DB: Verificar sustitutos activos
    DB-->>API: ApprovalSubstitute (si existe)
    API->>API: Reemplazar aprobador por sustituto

    API->>WRE: buildSnapshot() → WorkflowSnapshot
    API->>DB: UPDATE request status + approver
    API->>H: INSERT SolicitudHistorial (APROBADO/RECHAZADO)
    API->>WNS: notifyRequestApproved/Rejected()
    WNS->>WNS: dispatchToUser(email + push + in-app)

    Note over CRON,DB: Cada hora (0 * * * *)
    CRON->>DB: SELECT requests status=2, lastModDate > 48h
    CRON->>DB: UPDATE status=3 (Segunda Revisión)
    CRON->>H: INSERT SolicitudHistorial (ESCALADO)
    CRON->>WNS: notifyRequestEscalated()
```

---

## 4. Logística del viaje

CxP cotiza el costo impuesto, se consulta tipo de cambio a Banxico, se buscan vuelos/hoteles
via Duffel, la agencia atiende y selecciona ofertas.

```mermaid
sequenceDiagram
    participant CxP as Cuentas por Pagar
    participant APR as accountsPayableRoutes.js
    participant FX as exchangeRateRoutes.js
    participant BNX as Banxico REST API
    participant AG as Agencia de Viajes
    participant TAR as travelAgentRoutes.js
    participant FL as flightsRoutes.js
    participant HT as hotelsRoutes.js
    participant DUF as Duffel API
    participant DB as PostgreSQL
    participant TRG as prisma/middleware.js

    CxP->>APR: PUT /attend-travel-request/:request_id
    APR->>DB: UPDATE request status=4 (Cotización)
    APR->>DB: UPDATE imposed_fee
    DB->>TRG: Prisma $extends triggerExtension
    TRG->>DB: wallet -= imposed_fee (P39)

    CxP->>FX: GET /rate (moneda origen/destino)
    FX->>BNX: Consulta tasa del día
    BNX-->>FX: { rate, date }
    FX-->>CxP: Tasa de conversión

    CxP->>FX: POST /convert (monto, monedas)
    FX-->>CxP: { convertedAmount }

    Note over AG,DUF: Agencia cotiza vuelos y hoteles

    AG->>FL: POST /flights/search
    FL->>DUF: Search offers
    DUF-->>FL: Flight offers[]
    FL-->>AG: Opciones de vuelo

    AG->>HT: POST /hotels/search
    HT->>DUF: Search properties
    DUF-->>HT: Hotel results[]
    HT-->>AG: Opciones de hotel

    AG->>HT: POST /hotels/search-results/:id/rates
    HT->>DUF: Fetch rates
    DUF-->>HT: Rate details
    HT-->>AG: Tarifas detalladas

    AG->>TAR: PUT /attend-travel-request/:request_id
    TAR->>DB: UPDATE request status=5 (Atención Agencia)

    AG->>TAR: PUT /travel-request/:id/selected-flight
    TAR->>DB: Save selected flight offer

    AG->>TAR: PUT /travel-request/:id/selected-hotel
    TAR->>DB: Save selected hotel offer
```

---

## 5. Comprobación de gastos

El solicitante sube PDF/XML a S3, crea gastos por tramo, vincula recibos y parsea CFDI.

```mermaid
sequenceDiagram
    participant SOL as Solicitante
    participant FR as fileRoutes.js
    participant S3 as AWS S3
    participant GTR as gastoTramoRoutes.js
    participant APR as applicantRoutes.js
    participant CFR as comprobantesRoutes.js
    participant CPS as cfdiParserService.js
    participant DB as PostgreSQL

    SOL->>FR: POST /upload-receipt-files/:receipt_id
    FR->>S3: PutObject (PDF y/o XML)
    S3-->>FR: { fileId, key, url }
    FR->>DB: INSERT file metadata

    SOL->>GTR: POST /:id/tramos/:tramo_id/gastos
    GTR->>DB: INSERT gasto vinculado a tramo

    SOL->>GTR: GET /:id/resumen-tramos
    GTR->>DB: Query gastos agrupados por tramo
    GTR-->>SOL: Resumen consolidado

    SOL->>APR: POST /create-expense-validation
    APR->>DB: INSERT receipts con montos y tipo

    Note over SOL,CPS: Si el gasto tiene XML CFDI

    SOL->>CFR: POST /parse-xml
    CFR->>CPS: parseCFDI(xmlString)
    CPS->>CPS: fast-xml-parser (v3.3 / v4.0)
    CPS->>CPS: Extraer: UUID, RFC emisor/receptor, total, impuestos
    CPS->>CPS: Validar formato y campos obligatorios
    CPS-->>CFR: { version, uuid, rfcEmisor, total, taxes }
    CFR-->>SOL: Preview de datos fiscales

    SOL->>CFR: POST /comprobantes/:receipt_id
    CFR->>CPS: buildComprobanteRegistroBodyFromXml()
    CPS-->>CFR: Payload mapeado a schema API
    CFR->>DB: INSERT CfdiComprobante

    SOL->>APR: PUT /send-expense-validation/:request_id
    APR->>DB: UPDATE request status=7 (Validación Comprobantes)
```

---

## 6. Cierre y reembolso

CxP valida recibos, los triggers Prisma actualizan wallets, el motor de reembolso evalúa
políticas, se genera la póliza contable y se finaliza la solicitud.

```mermaid
sequenceDiagram
    participant CxP as Cuentas por Pagar
    participant APR as accountsPayableRoutes.js
    participant TRG as prisma/middleware.js
    participant RRE as refundRuleEngine.js
    participant PS as policyService.js
    participant RFR as refundRoutes.js
    participant DB as PostgreSQL
    participant CRON as refundDeadlineJob (daily)

    CxP->>APR: PUT /validate-receipt/:receipt_id
    APR->>DB: UPDATE receipt status = aprobado
    DB->>TRG: Prisma $extends triggerExtension
    TRG->>DB: wallet += receipt.amount (P40)

    CxP->>APR: PUT /validate-receipts/:request_id
    APR->>DB: UPDATE all receipts (batch)

    Note over RRE,PS: Evaluación de políticas

    CxP->>RFR: GET /request/:requestId/summary
    RFR->>RRE: findApplicablePolicy(policies, ctx)
    RRE->>RRE: Scoring: categoryId+CC=4, categoryId=3, CC=2, catch-all=1
    RRE-->>RFR: Best matching policy

    RFR->>RRE: evaluateReceiptAgainstPolicy(receipt, caps, policy)
    RRE->>RRE: Check per_night / per_trip / per_day / per_event caps
    RRE-->>RFR: { ok, exceeded, excessByCap }

    RFR->>RRE: summarizeRequestPolicyResult()
    RRE-->>RFR: { claimed, allowed, excess }

    RFR->>RRE: buildPolicyEvaluationSnapshot()
    RRE-->>RFR: Immutable snapshot (RF-46)

    CxP->>PS: snapshotPolicyForRequest(tx, requestId, ctx)
    PS->>DB: Freeze policy into request

    CxP->>APR: POST /polizas/:request_id/generar
    APR->>DB: INSERT Poliza (AV/GV snapshot)
    APR->>DB: UPDATE request status=8 (Finalizado)

    Note over CRON,DB: Diario 03:00 (0 3 * * *)
    CRON->>DB: reimbursementTimeService.lockExpiredRequests()
    CRON->>DB: Bloquear solicitudes que exceden plazo (RF-39)
```

---

## 7. Validación CFDI ante SAT

Upload del XML, parseo con `cfdiParserService` (fast-xml-parser para v3.3 y v4.0),
consulta SOAP al SAT, verificación EFOS y almacenamiento en PostgreSQL.

```mermaid
sequenceDiagram
    participant CxP as Cuentas por Pagar
    participant CFR as comprobantesRoutes.js
    participant CPS as cfdiParserService.js
    participant SAT as satConsultaService.js
    participant SOAP as SAT SOAP (ConsultaCFDI)
    participant DB as PostgreSQL

    CxP->>CFR: GET /comprobantes/:id/validacion-sat
    CFR->>DB: SELECT CfdiComprobante by id
    DB-->>CFR: { uuid, rfcEmisor, rfcReceptor, total }

    CFR->>SAT: consultarEstadoCFDI(uuid, rfcEmisor, rfcReceptor, total)
    SAT->>SAT: Construir envelope SOAP
    SAT->>SOAP: POST ConsultaCFDIService
    SOAP-->>SAT: { CodigoEstatus, EsCancelable, Estado, EstatusCancelacion }

    SAT->>SAT: Verificar Estado = "Vigente"
    SAT->>SAT: Check lista EFOS (69-B CFF)
    SAT-->>CFR: { estado, esCancelable, efosCheck }

    CFR->>DB: UPDATE CfdiComprobante.validacion_sat
    CFR-->>CxP: Resultado de validación SAT

    Note over CxP,DB: Flujo completo de CFDI

    rect rgb(240, 248, 255)
        CxP->>CFR: POST /comprobantes/parse-xml (preview)
        CFR->>CPS: parseCFDI(xmlString)
        CPS->>CPS: Detectar versión (v3.3 o v4.0)
        CPS->>CPS: fast-xml-parser → extraer nodos
        CPS->>CPS: Validar UUID, RFC, campos obligatorios
        CPS-->>CFR: Datos fiscales parseados
        CFR-->>CxP: Preview del comprobante

        CxP->>CFR: POST /comprobantes/:receipt_id
        CFR->>CPS: buildComprobanteRegistroBodyFromXml()
        CPS->>CPS: Mapear SAT fields → snake_case schema
        CPS-->>CFR: Payload de registro
        CFR->>DB: INSERT CfdiComprobante vinculado a receipt
    end
```

---

## 8. Políticas y excepciones de reembolso

Admin configura `TravelPolicy` con topes por categoría de empleado, `policyService.previewReceipt()`
evalúa en tiempo real, se crean excepciones cuando se excede, el aprobador decide, y el cron
`refundDeadlineJob` bloquea vencidos.

```mermaid
sequenceDiagram
    participant ADM as Admin
    participant PR as policyRoutes.js
    participant PS as policyService.js
    participant RFR as refundRoutes.js
    participant RRE as refundRuleEngine.js
    participant APR as Aprobador (N1/N2)
    participant CRON as refundDeadlineJob (daily 03:00)
    participant DB as PostgreSQL

    Note over ADM,DB: Fase 1: Configuración de políticas

    ADM->>PR: POST /policies (topes por receipt_type + categoría)
    PR->>PS: createPolicy(orgId, payload)
    PS->>PS: Detectar solapamiento con políticas existentes
    PS->>DB: INSERT TravelPolicy + PolicyCap[]
    PS-->>ADM: Política creada

    ADM->>PR: GET /policies (listar vigentes)
    PR->>PS: listPolicies(orgId, filters)
    PS-->>ADM: Lista con caps y categorías

    Note over ADM,DB: Fase 2: Evaluación en tiempo real

    ADM->>PR: POST /policies/preview (receipt simulado)
    PR->>RRE: findApplicablePolicy(policies, ctx)
    RRE->>RRE: Scoring: categoryId+CC=4, categoryId=3, CC=2, catch-all=1
    RRE->>RRE: evaluateReceiptAgainstPolicy(receipt, caps, policy)
    RRE-->>PR: { ok: false, exceeded: true, excessByCap }
    PR-->>ADM: Preview: excede tope en $X

    Note over RFR,DB: Fase 3: Gestión de excepciones

    RFR->>DB: POST /exceptions (CxP solicita excepción)
    DB-->>RFR: Exception creada (status=pending)

    RFR->>RFR: GET /exceptions/pending
    RFR-->>APR: Lista de excepciones pendientes

    APR->>RFR: POST /exceptions/:id/decide
    RFR->>DB: UPDATE exception (approved/rejected)
    RFR-->>APR: Decisión registrada

    Note over CRON,DB: Fase 4: Bloqueo automático de vencidos

    CRON->>DB: reimbursementTimeService.lockExpiredRequests()
    CRON->>DB: SELECT requests con deadline excedido
    CRON->>DB: UPDATE → bloquear solicitudes vencidas (RF-39)
```

---

## 9. Workflow dinámico con escalamiento

Admin crea reglas de workflow, el motor evalúa al enviar la solicitud, el resolver determina
los aprobadores N1/N2, si hay timeout el cron escala automáticamente, y todo queda en `SolicitudHistorial`.

```mermaid
sequenceDiagram
    participant ADM as Admin
    participant WRR as workflowRuleRoutes.js
    participant SOL as Solicitante
    participant SWR as solicitudWorkflowRoutes.js
    participant WRE as workflowRulesEngine.js
    participant AR as approverResolver.js
    participant DB as PostgreSQL
    participant CRON as escalationJob (hourly)
    participant WNS as workflowNotificationService.js
    participant H as SolicitudHistorial

    Note over ADM,DB: Fase 1: Configuración de reglas

    ADM->>WRR: POST /workflow-rules (regla por importe/moneda/destino)
    WRR->>DB: INSERT WorkflowRule
    ADM->>WRR: POST /workflow-rules/preview
    WRR->>WRE: computeLevelsFromRules(rules, simulatedCtx)
    WRE-->>WRR: { levels, maxApprovalLevel, skipApplied }
    WRR-->>ADM: Preview: solicitud iría a nivel N

    ADM->>WRR: PATCH /workflow-rules/:id/toggle
    WRR->>DB: UPDATE rule.active = !active

    Note over SOL,DB: Fase 2: Solicitud enviada

    SOL->>SWR: POST /:id/aprobar
    SWR->>WRE: computeLevelsFromRules(rules, ctx)
    WRE->>WRE: ruleMatches(rule, ctx) para cada regla activa
    WRE->>WRE: maxLevelFromImporteBands(amount, matchingRules)
    WRE-->>SWR: { levels, maxApprovalLevel }

    SWR->>AR: resolveN1N2Approvers(db, orgId, deptId, userId)
    AR->>DB: Query manager chain (max 10 niveles)
    AR-->>SWR: { n1UserId, n2UserId }

    SWR->>WRE: buildSnapshot()
    SWR->>WRE: initialStatusFromLevels()
    WRE-->>SWR: status = 2 (N1) o 3 (N2)

    SWR->>DB: UPDATE request (status, approver)
    SWR->>H: INSERT SolicitudHistorial (ENVIADO)
    SWR->>WNS: notifyRequestSubmitted(requestId)
    WNS->>WNS: dispatchToUser(email + push + in-app)

    Note over CRON,DB: Fase 3: Escalamiento automático

    CRON->>DB: SELECT requests status=2, lastModDate > 48h
    CRON->>DB: UPDATE status = 3 (Segunda Revisión)
    CRON->>H: INSERT SolicitudHistorial (ESCALADO)
    CRON->>WNS: notifyRequestEscalated(requestId)
    WNS->>WNS: Notificar a N2
```

---

## 10. Multi-tenant onboarding

Admin Ditta crea la organización cliente via API, bootstrap siembra catálogos, el admin de la
organización importa usuarios, y el tenant extension auto-scopes todas las queries.

```mermaid
flowchart TD
    subgraph Ditta["Admin Ditta (Org ROOT)"]
        A1[POST /api/organizations] --> A2[organizationService.create]
        A2 --> A3[PostgreSQL: INSERT Organization kind=CLIENT]
    end

    A3 --> B[bootstrapOrganization.js]

    subgraph Bootstrap["Bootstrap automático"]
        B --> B1[Roles x7: Solicitante, N1, N2,\nAgencia, CxP, Admin, Observador]
        B --> B2[Permission Groups x8:\nBaseColaborador, TravelRequestAuthor,\nOrgAdmin, etc.]
        B --> B3[Receipt Types x7:\nHospedaje, Comida, Transporte, etc.]
        B --> B4[Alert Messages x7]
        B --> B5[Notification Templates x4]
        B --> B6[Chart of Accounts defaults]
        B --> B7[ensureOrganizationAdmin:\ncrea admin inicial]
    end

    B7 --> C[Admin Org accede al sistema]

    subgraph Import["Importación de usuarios"]
        C --> D1[POST /api/onboarding-import/preview]
        D1 --> D2[onboardingImportService.previewImport]
        D2 --> D3{Formato?}
        D3 -->|CSV| D4[Parsear CSV]
        D3 -->|JSON| D5[Parsear JSON]
        D4 --> D6[Validar + inferir roles\npor jerarquía de managers]
        D5 --> D6
        D6 --> D7[Preview token + resumen\nTTL: 10 min]
        D7 --> D8[Admin revisa y confirma]
        D8 --> D9[POST /api/onboarding-import/apply]
        D9 --> D10[applyImport: crear users +\nemployees + manager links]
    end

    D10 --> E[tenantExtension.js]

    subgraph Tenant["Aislamiento automático"]
        E --> E1["set_config('app.current_organization_id', orgId)"]
        E1 --> E2[applyTenantScopingToArgs:\nauto-inject organization_id]
        E2 --> E3[39 modelos con scope automático]
        E3 --> E4{bypassTenant?}
        E4 -->|No| E5[Queries filtradas por org]
        E4 -->|Sí Admin Ditta| E6[Queries cross-tenant]
    end

    E5 --> F[Organización operativa\ncon aislamiento RLS]
```

---

## Referencias cruzadas

- [Lista de Procesos](lista-procesos.md) — inventario de 167 procesos por dominio, endpoint y trigger
- [Service Blueprint](service-blueprint.md) — macro-procesos y swimlanes operativos
- [Flujos](flujos.md) — estados de solicitud y diagramas de secuencia API
- [Multi-tenancy](multi-tenancy.md) — detalle de aislamiento por organización
