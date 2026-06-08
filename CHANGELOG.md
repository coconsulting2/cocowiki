# Changelog — CocoWiki

Cambios en la documentación publicada en **GitHub Pages** (carpeta `docs/`). La versión en [`VERSION`](VERSION) es la de **esta wiki**, no del producto TC3005B.

El formato se inspira en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [1.4.0] - 2026-06-08

Documentado el CD real (git-poll server-side) que reemplazó al esquema GHCR/SSH.

### Cambiado

- **`getting-started/deploy-aws.md` §7**: reescrita la sección de CI/CD. Antes describía el `deploy.yml` (GitHub Actions con SSH a la EC2), que quedó superado. Ahora documenta el **auto-deploy por git-poll**: timer systemd `coco-redeploy.timer` + `redeploy.sh` que instala `install.sh` (default `REDEPLOY_INTERVAL=2min`, `OnBootSec=3min`), con diagrama de secuencia, tabla de operación (estado / forzar ciclo / logs / cambiar intervalo), las unidades systemd generadas, la vía **AWS SSM** cuando el puerto 22 está bloqueado, y una nota de legacy (GHCR `amd64` no corre en host `arm64`; `deploy.yml` dependía de secrets SSH).
- **`arquitectura-datos/diagramas-c4.md`** (v1.0.1): corregido el "Pipeline CI/CD" y el glosario — el despliegue es git-poll en la EC2, no `docker compose pull` desde GHCR.
- **`arquitectura-datos/documento-arquitectura.md`**: misma corrección en el pipeline CI/CD y el glosario.
- **`arquitectura-datos/service-blueprint.md`** (v1.0.2): fila "CI/CD" del inventario y glosario actualizados al despliegue por git-poll.

## [1.3.0] - 2026-06-05

Documentación enfocada en el frontend para la entrega final.

### Añadido

- **`desarrollo/estilo-codigo-frontend.md`** (v1.0.0) — guía de convenciones específicas del frontend: extensiones por capa, estructura de `src/`, alias de ruta, patrones de componentes React/islas Astro, cliente `apiRequest` (Bearer + CSRF + `X-Organization-Id`), manejo de errores/avisos, estilos Tailwind, formularios, RBAC (`routeAccess` + `middleware` + `menu-config`) y testing. Entrada en la barra lateral y cross-link desde el estilo de código general.

### Cambiado

- **`getting-started/setup-frontend.md`**: documentada la capa de tests unitarios/de componentes con **Vitest** (ubicación, MSW, umbral 70%); nueva tabla de **scripts** (`bun run …`); nota sobre el HMR deshabilitado; el stack ahora lista Vitest además de Cypress y enlaza al estilo de código del frontend.
- **`guias-usuario/flujos-pantallas-por-rol.md`** (v1.0.3): añadida la **matriz de rutas × rol** derivada de `src/config/routeAccess.ts`, con la única diferencia entre Administrador y Admin Ditta (`/admin/workflow-rules`).
- **`desarrollo/estilo-codigo-documentacion.md`**: el stack del frontend ahora lista Vitest + Cypress y enlaza a la nueva guía de estilo del frontend.

## [1.2.0] - 2026-06-02

Sincronización integral del contenido con el estado actual del código (backend + frontend) tras el refactor multi-tenant y el trabajo reciente de onboarding-import y API keys / export ERP. Se auditaron 17 documentos y se actualizaron 16 (`qa/ber-bmx.e2e.test.md` ya estaba al día).

### Cambiado

- **Modelo ER** (`arquitectura-datos/modelo-er.md` → v1.2.0): de ~15 a los 43 modelos del schema Prisma; `organization_id` y claves únicas por-organización en todas las entidades multi-tenant; 6 sub-diagramas Mermaid por dominio; enums (`OrganizationKind`, `OrganizationStatus`, `SolicitudHistorialAccion`, `PolicyExceptionStatus`) y tabla de estados `Request_status`; campos CFDI inline en `Receipt`.
- **Sistema de permisos** (`arquitectura-datos/permisos.md` → v1.1.0): catálogo completo de 48 permisos atómicos en 21 namespaces; grupo `DittaSuperAdmin` y rol Admin Ditta (ROOT); grupos `BaseColaborador`/`TravelNotifyOnly` y rol `Observador`; cadena de middleware real (`tenantContext` + `applyRlsForRequest`).
- **Flujos y API** (`arquitectura-datos/flujos.md` → v1.1.0): los 27 routers montados en `app.js` (antes 8); máquina de estados de solicitud corregida (cancelación desde estados 1–5, paso de agencia opcional, N1 puede saltar N2, rollback de validación); roles Observador y Admin Ditta; capas Routes→Controllers→Services→Models→Prisma.
- **Multi-tenant** (`arquitectura-datos/multi-tenancy.md`): SQL real de la política RLS (`NULLIF` + `WITH CHECK`); el `set_config` lo aplica `applyRlsForRequest`, no la extensión de Prisma; helper transaccional `withRls`; doble compuerta de impersonación `X-Organization-Id`; grace period de 24 h por defecto.
- **Guías de setup**: puerto Postgres host `5434`; variable `API_URL_SSR`; LocalStack S3 + `s3-init`; seed idempotente en cada `up`; PostgreSQL 16 / MongoDB 7; nota sobre `seed-usability.js` para los usuarios CocoUAT.
- **Guías de usuario** (usuario, admin, flujos por rol): "SOI" → "Cuentas por pagar"; entrada "LLAVES API" en los menús; diálogo de sesión expirada; CTA "Subir comprobantes"; login por nombre de usuario; importación `.json`/`.csv`/`.txt` con badge "auto-detectado" y "Crear organización nueva"; botón "Ver usuarios" en organizaciones.
- **CFDI/SAT y QA**: servicio real `satConsultaService.js`; `bun add soap`; validación síncrona; regla de rechazo EFOS (Art. 69-B); endpoints `parse-xml` e `is_international`; conteos de pruebas (16 Cypress / 24 Vitest); `bunx cypress`; opciones multi-tenant de `createTestJWT`.

### Corregido

- **`getting-started/setup-frontend.md`**: eliminada la sección obsoleta de "modo mock" (`mockCookies`), código muerto desde la migración multi-tenant; documentado el flujo real de sesión por cookies httpOnly y la configuración de Cypress (`bunx`, usuarios CocoUAT).
- **`desarrollo/estilo-codigo-documentacion.md`**: eliminada la referencia a MariaDB; añadidos Bun (gestor de paquetes) y Prisma 6 (ORM) al stack.
- **`arquitectura-datos/documento-arquitectura.md`**: SOAP atribuido a `satConsultaService.js` (no `cfdiParserService.js`); rutas reales de los tests e2e de CFDI; aclaración driver `mongodb@5` vs servidor MongoDB 7.

## [1.1.0] - 2026-06-01

### Cambiado

- **Reorganización de `docs/` en carpetas temáticas** para mejorar la navegación. Los documentos antes sueltos en la raíz se agruparon en `getting-started/` (setup), `arquitectura-datos/` (modelo ER, flujos, permisos, multi-tenant), `guias-usuario/` (manuales + flujos por rol), `desarrollo/` (estilo, CFDI/SAT, changelog de errores), `qa/` (renombrada desde `tests/`) y `proyecto/` (nosotros, análisis de esfuerzos).
- `_sidebar.md` reescrito con 7 grupos alineados a las carpetas.
- Cross-links internos y rutas relativas al monorepo ajustados a las nuevas ubicaciones.
- **Nombres de archivo normalizados a kebab-case:** `MANUAL_USUARIO`→`manual-usuario`, `MANUAL_ADMIN`→`manual-admin`, `TESTING`→`testing`, `estiloCodigo-documentacion`→`estilo-codigo-documentacion`, `documentacionAPI-SAT`→`documentacion-api-sat`, `documentacion_pruebas_caja_negra`→`documentacion-pruebas-caja-negra`, `analisis_esfuerzos`→`analisis-esfuerzos`.

### Añadido

- Incluidos en la barra lateral tres documentos que existían pero no estaban enlazados: `desarrollo/documentacion-api-sat.md`, `qa/m2-006-casos-de-prueba.md` y `qa/log-de-defectos.md`.

### Corregido

- Etiqueta del sidebar: "Manual Técnico" → "Manual Admin Ditta" (apunta al manual del superadmin Ditta).
- **Guías de setup alineadas al stack real:** Bun en vez de pnpm, PostgreSQL 16 en vez de MariaDB, `DATABASE_URL` y variables `.env` vigentes, comandos `bun run dev`/`dummy_db`.
- Enlaces a código backend del reporte de caja negra (NT-003) repuntados a su ruta real; referencias obsoletas a `BLUEPRINT_SISTEMA`/`DIAGRAMA_SISTEMA_DETALLADO` (eliminadas del repo) desenlazadas.

## [1.0.2] - 2026-04-21

### Añadido

- `docs/flujos-pantallas-por-rol.md` — CocoAPI: flujos de pantallas por rol (7 roles, patrones compartidos); PNG en `docs/images/diagrams/pantallas/`. El `.md` está en la raíz de `docs/` para que `./images/…` coincida con el árbol del repo.
- Entrada en la barra lateral y enlaces desde `flujos.md`, `docs/README.md` y la tabla del `README` raíz.

## [1.0.1] - 2026-04-15

### Añadido

- `docs/arquitectura-datos/modelo-er.md` — diagrama ER (Mermaid) según `TC3005B.501-Backend/prisma/schema.prisma`.
- `docs/arquitectura-datos/flujos.md` — capas del sistema, rutas por rol, estados de solicitud, API → entidades, secuencias.
- Entrada en la barra lateral de Docsify y soporte **Mermaid** en `docs/index.html` para renderizar diagramas en el sitio estático.

### Cambiado

- La documentación de arquitectura de datos vive en **este repo (`cocowiki`)** para despliegue con GitHub Pages; ya no en la carpeta `wiki/` del monorepo padre.

## [1.0.0] - 2026-04-15

### Añadido

- Versión inicial registrada en este changelog (contenido previo de CocoWiki sin numeración explícita).
