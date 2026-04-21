# CocoWiki

Documentación del proyecto (**Docsify**), servida con **GitHub Pages** desde la carpeta `docs/`.

## Contenido destacado

| Sección | Ruta |
|---------|------|
| Arquitectura de datos — modelo ER | [docs/arquitectura-datos/modelo-er.md](docs/arquitectura-datos/modelo-er.md) |
| Arquitectura de datos — flujos y pantallas | [docs/arquitectura-datos/flujos.md](docs/arquitectura-datos/flujos.md) |
| Arquitectura de datos — flujos por rol (diagramas) | [docs/arquitectura-datos/flujos-pantallas-por-rol.md](docs/arquitectura-datos/flujos-pantallas-por-rol.md) |
| Resto de guías | [docs/](docs/) (sidebar en `_sidebar.md`) |

## Versión de la wiki

- Número actual: [`VERSION`](VERSION).
- Historial: [`CHANGELOG.md`](CHANGELOG.md).

### Cómo versionar

1. Tras editar documentos bajo `docs/`, añade una entrada en `CHANGELOG.md` y sube `VERSION` (semver) según impacto:
   - **MAJOR**: reestructuración fuerte del ER o eliminación de secciones arquitectónicas.
   - **MINOR**: nuevas páginas o diagramas sustanciales.
   - **PATCH**: correcciones menores, enlaces, redacción.
2. En cada página afectada, actualiza la tabla **Versión del documento** y **Última actualización** en la cabecera.

### Desarrollo local

```bash
npm run dev
```

Abre el servidor de Docsify sobre `./docs`.

### Enlaces al código (monorepo)

Si **cocowiki** está clonado dentro del monorepo (junto a `TC3005B.501-Backend` y `TC3005B.501-Frontend`), las páginas de arquitectura usan rutas relativas `../../../TC3005B...` hacia el código. En **solo** el repo de GitHub Pages esas rutas no apuntan a archivos en el mismo repo; abre el repositorio del producto para inspeccionar el código.
