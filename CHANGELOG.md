# Changelog — CocoWiki

Cambios en la documentación publicada en **GitHub Pages** (carpeta `docs/`). La versión en [`VERSION`](VERSION) es la de **esta wiki**, no del producto TC3005B.

El formato se inspira en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

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
