# Changelog — CocoWiki

Cambios en la documentación publicada en **GitHub Pages** (carpeta `docs/`). La versión en [`VERSION`](VERSION) es la de **esta wiki**, no del producto TC3005B.

El formato se inspira en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

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
