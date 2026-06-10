# Implantación y operación CocoAPI — Documento condensado

> Proyecto: **CocoAPI** · Cliente: **Ditta Consulting** · Equipo: **COCONSULTING2**
> Versión condensada para entrega académica · Última actualización: 2026-06-09

Este archivo integra en un solo lugar las cinco entregas de implantación, despliegue, uso y operación. El detalle paso a paso (capturas, scripts completos, procedimientos extendidos) permanece en los documentos enlazados.

---

## 1. Implantación de Software

**Alcance:** poner en marcha CocoAPI en **desarrollo local** (Docker o host) antes de desplegar a producción.

| Componente | Stack | Notas |
|------------|-------|-------|
| Backend | Node 22 · Bun · Express · Prisma 6.16 · PostgreSQL 16 | Hot-reload en dev; entrypoint con certs, `db push` y seed en prod |
| Frontend | Astro 5.7 SSR · React 19 · Tailwind 4.1 | Islas React; `apiClient` con JWT + CSRF |
| Datos dev | Postgres 16 + LocalStack S3 | Job `migrate` one-shot; bucket `coco-consulting-local` |
| Runtime host | Docker Desktop / Engine + Compose v2 | Flujo canónico del equipo; Bun en host opcional (atajos `docker:*`) |

**Pasos resumidos (desarrollo):**

1. Instalar Docker (+ Bun opcional) y clonar los tres repos (`cocowiki`, `TC3005B.501-Backend`, `TC3005B.501-Frontend`).
2. Backend: `docker compose -f docker-compose.dev.yml up` → Postgres, LocalStack, migrate, API `:3000` (HTTPS autofirmado).
3. Frontend: `docker compose -f docker-compose.dev.yml up` o `bun run dev` apuntando al backend.
4. Alternativa sin Docker: ver guías de setup por repo (Postgres 16, variables `.env`, `bun install`, certs, Prisma).

**Repositorios:** backend y frontend en GitHub (`coconsulting2/*`); wiki en `cocowiki`.

**Fuentes:** [setup-docker.md](getting-started/setup-docker.md) · [setup-backend.md](getting-started/setup-backend.md) · [setup-frontend.md](getting-started/setup-frontend.md)

---

## 2. Estrategia de Despliegue

**Alcance:** llevar CocoAPI a **producción demo** en AWS (una EC2, una AZ, un ambiente productivo; dev local sin staging).

| Aspecto | Decisión |
|---------|----------|
| **Infra demo** | EC2 `t4g.small` ARM · AL2023 · Caddy TLS · Compose (Caddy + FE + BE + Postgres co-locado) · S3 privado SSE-S3 |
| **CI** | GitHub Actions en push/PR: lint, Prisma validate, tests (`ci.yml`) — **no despliega** a EC2 |
| **CD** | Git-poll server-side: timer systemd `coco-redeploy.timer` (default **2 min**) → `redeploy.sh` → `git fetch` de `main` → si avanzó, `docker compose up -d --build` |
| **Build prod** | Nativo arm64 en la instancia (sin registry obligatorio); imágenes `production` en Dockerfiles |
| **Seeding** | `--seed=demo|admin|none` en `install.sh`; credenciales demo documentadas en deploy-aws |
| **Limitación** | Sin zero-downtime: cada release puede generar ventana de indisponibilidad durante rebuild+recreate |

**Flujo de provisión (desde cero):**

1. **Opción A:** `deploy-all.sh` (provision + install en un paso).
2. **Opción B:** `aws-provision.sh` (subnet, SG, S3, IAM, EC2, EIP) → SSH → `install.sh` (clone, `.env`, build, up, timer CD).
3. Merge a `main` → la EC2 se auto-actualiza en ≤ intervalo de poll.

**Scripts clave:** `cocowiki/deploy/` — `aws-provision.sh`, `install.sh`, `redeploy.sh`, `docker-compose.prod.yml`, `aws-teardown.sh`.

**Fuentes:** [deploy-aws.md](getting-started/deploy-aws.md) · [arquitectura-nube.md](arquitectura-datos/arquitectura-nube.md) · [documento-arquitectura.md sección 4](arquitectura-datos/documento-arquitectura.md#4-arquitectura-de-infraestructura)

---

## 3. Manual de Usuario

**Audiencia:** roles operativos del ciclo de viaje (excepto Admin Ditta).

| Rol | Capacidades principales |
|-----|-------------------------|
| **Solicitante** | Crear solicitudes, rutas, comprobantes CFDI/internacionales, seguimiento |
| **N1 / N2** | Bandeja de aprobación, aprobar/rechazar, comentarios |
| **Cuentas por pagar** | Validación de comprobantes, cotización |
| **Agencia** | Cotización vuelo/hotel (Duffel o mock), atención de solicitudes |
| **Admin org** | Usuarios, roles, workflow, políticas, importación CSV (dentro de su tenant) |

**Contenido del manual completo (v1.0.1):**

- Acceso: login por usuario/contraseña; org opcional; sin autoregistro.
- Navegación: sidebar por rol, dashboard, perfil, cierre de sesión.
- Flujo de solicitud: borrador → revisiones → cotización → agencia → comprobación → validación → finalizado.
- Estados, FAQ, glosario y funcionalidades en desarrollo.

**Complemento visual:** [flujos-pantallas-por-rol.md](guias-usuario/flujos-pantallas-por-rol.md) (diagramas M1–M3).

**Fuente:** [manual-usuario.md](guias-usuario/manual-usuario.md)

---

## 4. Manual Administrador

**Audiencia:** administración de la plataforma — distingue dos perfiles:

| Perfil | Alcance | Documento |
|--------|---------|-----------|
| **Admin Ditta** (ROOT) | Multi-tenant: onboarding orgs, impersonación, usuarios cross-org, catálogo contable maestro, API keys, políticas globales | [manual-admin.md](guias-usuario/manual-admin.md) |
| **Admin de organización** | Usuarios, roles, reglas de workflow, políticas de viáticos, importación — solo su `organization_id` | [manual-usuario.md sección 8](guias-usuario/manual-usuario.md) |

**Admin Ditta — temas clave:**

- Organizaciones: crear, activar, suspender, impersonar (`X-Organization-Id`).
- Usuarios en cualquier tenant; no gestiona solicitudes operativas ni workflow por org.
- Catálogos: contabilidad, indicadores de impuesto, mapeo gastos, llaves API ERP.
- Checklist de onboarding de nueva organización; procedimientos de emergencia.

**Fuentes:** [manual-admin.md](guias-usuario/manual-admin.md) · [multi-tenancy.md](arquitectura-datos/multi-tenancy.md) · [permisos.md](arquitectura-datos/permisos.md)

---

## 5. Manual de Operación

**Audiencia:** operadores de infraestructura y soporte (DevOps / equipo técnico). No existe un manual operativo monolítico aparte; el contenido se distribuye en runbooks y secciones de despliegue.

| Área | Qué cubre | Dónde |
|------|-----------|-------|
| **CD en producción** | Estado del timer, forzar redeploy, logs, cambiar intervalo, SSM sin SSH | [deploy-aws.md sección 7](getting-started/deploy-aws.md) |
| **Variables y secretos** | `deploy/.env` (chmod 600), IAM instance role para S3, integraciones opcionales | [deploy-aws.md sección 5](getting-started/deploy-aws.md) |
| **TLS / dominio** | Cert auto-firmado vs ACME con dominio real | [deploy-aws.md sección 8](getting-started/deploy-aws.md) |
| **Backup y restore PG** | `pg_dump` diario, copia off-instance, `pg_restore`, recuperación EC2 | [documento-arquitectura.md sección 6.2](arquitectura-datos/documento-arquitectura.md#62-estrategia-de-respaldo-y-runbook-postgresql--s3) |
| **Continuidad (RTO/RPO)** | Escenarios A/B/C, git-poll, ventanas de deploy | [documento-arquitectura.md sección 6.1](arquitectura-datos/documento-arquitectura.md#61-rto-recovery-time-objective) |
| **Teardown / costos** | Stop/start EC2, terminate, liberar EIP | [deploy-aws.md sección 9](getting-started/deploy-aws.md) |
| **Troubleshooting** | Logs Compose, salud contenedores, errores frecuentes | [deploy-aws.md sección 10](getting-started/deploy-aws.md) |

**Comandos operativos frecuentes (en la EC2):**

```text
sudo systemctl status coco-redeploy.timer    # próximo ciclo CD
sudo systemctl start coco-redeploy.service   # forzar redeploy
sudo journalctl -u coco-redeploy.service -f   # logs CD
cd /opt/coco/cocowiki/deploy && sudo docker compose -f docker-compose.prod.yml ps
sudo docker compose -f docker-compose.prod.yml logs -f backend
```

**Monitoreo demo:** healthcheck en imágenes backend/frontend; logs vía `docker compose logs` y journald; sin CloudWatch centralizado en auto-setup.

**Fuentes:** [deploy-aws.md](getting-started/deploy-aws.md) · [documento-arquitectura.md secciones 6.1–6.2](arquitectura-datos/documento-arquitectura.md#6-indicadores-de-continuidad-de-negocio-rto--rpo--sla) · scripts en `cocowiki/deploy/`

---

## Mapa de documentos fuente

| Entrega | Documento principal | Detalle / anexo |
|---------|---------------------|-----------------|
| Implantación | setup-docker.md | setup-backend.md, setup-frontend.md |
| Estrategia de despliegue | deploy-aws.md | arquitectura-nube.md, `cocowiki/deploy/*` |
| Manual de usuario | manual-usuario.md | flujos-pantallas-por-rol.md, Historias-de-usuario |
| Manual administrador | manual-admin.md (Ditta) | manual-usuario.md §8 (admin org), permisos.md |
| Manual operación | deploy-aws.md §7–10 | documento-arquitectura.md §6.1–6.2, redeploy.sh |

> **Exportar a Word/PDF:** abrir este archivo en Docsify / VS Code y usar *Imprimir → PDF*, o Pandoc: `pandoc implantacion-condensada.md -o entrega-implantacion.docx`.
