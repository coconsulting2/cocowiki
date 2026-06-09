# Arquitectura CocoAPI — Documento condensado

> Proyecto: **CocoAPI** · Cliente: **Ditta Consulting** · Equipo: **COCONSULTING2**
> Versión condensada para entrega académica · Última actualización: 2026-06-09
> Documento técnico completo: [documento-arquitectura.md](documento-arquitectura.md)

Este archivo integra en un solo lugar las seis capas de arquitectura solicitadas. El detalle ampliado (diagramas C4, ER por subdominio, pruebas RNF) permanece en los documentos enlazados.

---

## 1. Arquitectura de Negocio

**Propósito:** portal web de gestión de viáticos y reembolsos, ERP-agnóstico, multi-tenant (Ditta ROOT + clientes).

**Actores:** Solicitante, N1/N2 (aprobadores configurables), Cuentas por pagar, Agencia, Admin org, Admin Ditta, Observador, ERP externo.

**Flujo canónico:** captura → N1 → N2 → CxP → agencia → comprobación CFDI → exportación contable.

**Contexto Ditta:** partner SAP; objetivos = automatizar fiscal (SAT/CFDI), workflow dinámico por importe/org, API contable sin duplicar plan de cuentas del ERP.

**Fuentes:** [service-blueprint.md](service-blueprint.md) · [Historias de usuario](../proyecto/Historias-de-usuario_cocoAPI.md)

---

## 2. Arquitectura de Aplicación

| Capa | Tecnología |
|------|------------|
| Frontend | Astro 5.7 SSR + React 19 + Tailwind 4.1 |
| Backend | Express 4.18 · Node 22 · 30 rutas · 71 servicios |
| ORM | Prisma 6.16 → PostgreSQL 16 |
| Auth | JWT + CSRF + RBAC `resource:action` |

**Pipeline protegido:** `authenticateToken` → `tenantContext` → RLS → `loadPermissions` → `authorizePermission`.

**Integraciones:** SAT (SOAP + XML), Banxico/DOF, Duffel, S3 pre-signed, SMTP, Web Push, API Key M2M.

**Fuentes:** [arquitectura-aplicacion.md](arquitectura-aplicacion.md) (stack sección 0, capas backend sección 1, capas frontend sección 2) · [diagramas-c4.md](diagramas-c4.md)

---

## 3. Arquitectura de Datos

- **PostgreSQL:** 49 modelos, 5 enums; multi-tenant con `organization_id` + RLS (38 tablas).
- **S3:** binarios de comprobantes; metadata en `Receipt` (`pdf_file_id`, `xml_file_id`).
- **CFDI:** tabla `cfdi_comprobantes` 1:0..1 con `Receipt`; tipo `INTERNACIONAL` para gastos extranjeros.
- **Catálogos globales:** Permission, Country, City, Request_status.

**Fuentes:** [modelo-er.md](modelo-er.md) · [multi-tenancy.md](multi-tenancy.md)

---

## 4. Arquitectura de Infraestructura

**Demo (auto-setup):** 1× EC2 `t4g.small` us-east-1a · Docker Compose (Caddy, FE, BE, Postgres) · S3 privado · ~12–15 USD/mes.

**CI:** GitHub Actions (lint, Prisma, tests). **CD:** git-poll systemd en EC2 (~2 min).

**Limitación consciente:** single-AZ, sin RDS/ALB; producción recomendada multi-AZ (~120–300+ USD/mes).

**Fuentes:** [arquitectura-nube.md](arquitectura-nube.md) · [deploy-aws.md](../getting-started/deploy-aws.md)

---

## 5. Requerimientos No Funcionales

**Técnicos (RNF-01…27):** verificados contra código — JWT, RLS, scrypt API keys, S3 SSE, BER cache, CFDI/SAT, etc.

| Estado | Cantidad |
|--------|----------|
| Cumplido | 22 |
| Parcial | 4 (RNF-13, 18, 20, 22) |
| Pendiente | 2 (RNF-11, 12 — carga/concurrencia) |

**Producto (RNF-P01…14):** responsive, dashboard, borradores, historial inmutable, etc.

**Fuentes:** [RNF_CocoAPI.md](../proyecto/RNF_CocoAPI.md) · [documento-arquitectura.md sección 5](documento-arquitectura.md#5-requerimientos-no-funcionales)

---

## 6. Continuidad de negocio (RTO / RPO / SLA)

| Indicador | Objetivo demo | Cómo lo cumple la arquitectura |
|-----------|---------------|--------------------------------|
| **RTO** | ≤ 2 h | Contenedores stateless; `docker compose up --build`; reprovision EC2 si falla la instancia |
| **RPO** | ≤ 24 h | `pg_dump` diario manual sobre vol. EBS; S3 durable para archivos |
| **SLA** | 99,0 % best-effort | Healthcheck + reinicio Docker; limitado por 1 EC2 / 1 AZ |

**Runbook:** backup PG diario → copia off-instance → restore con `pg_restore` → levantar stack.

Detalle: [documento-arquitectura.md sección 6](documento-arquitectura.md#6-indicadores-de-continuidad-de-negocio-rto--rpo--sla)

---

## Mapa de documentos fuente

| Sección | Documento principal | Detalle |
|---------|---------------------|---------|
| Negocio | documento-arquitectura.md sección 1 | service-blueprint.md, Historias-de-usuario |
| Aplicación | documento-arquitectura.md sección 2 | arquitectura-aplicacion.md, diagramas-c4.md |
| Datos | documento-arquitectura.md sección 3 | modelo-er.md, multi-tenancy.md |
| Infraestructura | documento-arquitectura.md sección 4 | arquitectura-nube.md, deploy-aws.md |
| RNF | RNF_CocoAPI.md | documento-arquitectura.md sección 5, qa/testing.md |
| Continuidad | documento-arquitectura.md sección 6 | arquitectura-nube.md |

> **Exportar a Word/PDF:** abrir este archivo o [documento-arquitectura.md](documento-arquitectura.md) en Docsify / VS Code y usar *Imprimir → PDF*, o Pandoc: `pandoc arquitectura-condensada.md -o entrega-arquitectura.docx`.
