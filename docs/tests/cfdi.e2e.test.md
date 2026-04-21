# Plan de pruebas del servicio de verificacion CFDI [NT-009]

**Division del alcance**

- `Mock Contract Scope`: comportamiento estricto de SAT para validacion de parametros y semantica de respuesta SAT.
- `Endpoint + DB E2E Scope`: comportamiento real de la API desde
  `PUT /api/accounts-payable/validate-receipt/:receipt_id` mas los efectos persistidos en la BD.

## Inicio rapido

> Nota
> Para ejecutar pruebas E2E debes tener ambas bases de datos en ejecucion y un `.env` valido para testing.

**Ejemplo de archivo env para testing:**

```dotenv

NODE_ENV=test
PORT=3000
DATABASE_URL=postgresql://cocoscheme:cocoscheme_dev@localhost:5432/CocoScheme?schema=public
MONGO_URI=mongodb://localhost:27017
CORS_ORIGIN=http://localhost:4321,https://localhost:4321
AES_SECRET_KEY=12345678901234567890123456789012
JWT_SECRET=dev_jwt_secret_change_me
MAIL_USER=test.mail@outlook.com
MAIL_PASSWORD=changeme

# Importante para testing
PRISMA_DISABLE_TRIGGERS=true

# Ejecutar e2e con SAT real
#RUN_REAL_SAT_TESTS=0
```

1. Ejecuta las pruebas

```bash

bun run test:e2e
```

## Servicio de verificacion CFDI `PUT /api/accouns-payable/validate-receipt/:id`

### **1. CFDI valido (Valid: S - 200 o 201)**

Un CFDI totalmente bien formado, existente, no expirado y no marcado por EFOS.

* **[TC-001-V-01] Standard Successful Query**: se envian `re`, `rr`, `tt` e `id` bien formados y se obtiene `S` (
  Comprobante obtenido satisfactoriamente) con codigo EFOS `200` (Emisor no incluido en lista EFOS).
* **[TC-002-V-02] Extended Parameter Success**: se envian `re`, `rr`, `tt`, `id` y `fe` bien formados y se obtiene `S`
  con codigo EFOS `200`.
    - Nota (E2E): actualmente omitido. El endpoint deja `selloUltimos8: null`, por lo que `fe` nunca se envia.
* **[TC-003-V-03] Comprehensive Clean Record**: se envian `re`, `rr`, `tt` e `id` bien formados y se obtiene `S` con
  codigo EFOS `201` (esto significa que ni el Emisor ni RFCs de terceros estan en lista EFOS).

---

### **2. CFDI no encontrado (Not Found: N - 602)**

Un CFDI completamente bien formado pero no encontrado por inexistencia, expiracion o datos incorrectos contra la base
SAT.

* **[TC-004-NF-01] Legacy Document Lookup**: se envian `re`, `rr`, `tt` e `id` bien formados, pero el comprobante es
  demasiado antiguo para reflejar existencia, y se obtiene `N - 602` (Comprobante no encontrado).
* **[TC-005-NF-02] Non-Existent UUID**: se envian `re`, `rr`, `tt` e `id` bien formados, pero con `UUID` falso, y se
  obtiene `N - 602`.
* **[TC-006-NF-03] RFC Emisor Mismatch**: se envian `re`, `rr`, `tt` e `id` bien formados, pero con `re` falso, y se
  obtiene `N - 602`.
* **[TC-007-NF-04] RFC Receptor Mismatch**: se envian `re`, `rr`, `tt` e `id` bien formados, pero con `rr` falso, y se
  obtiene `N - 602`.
* **[TC-008-NF-05] Total Amount Mismatch**: se envian `re`, `rr`, `tt` e `id` bien formados, pero con `tt` falso, y se
  obtiene `N - 602`.
* **[TC-009-NF-06] Sello (Seal) Mismatch**: se envian `re`, `rr`, `tt`, `id` y `fe` bien formados, pero con `fe` falso,
  y se obtiene `N - 602`.
    - Nota (E2E): actualmente omitido. El endpoint no propaga `fe`.

---

### **3. Solicitud CFDI mal formada (Not Valid: N - 601)**

Solicitud con formato incorrecto, valores faltantes o parametros que no respetan el formato definido, haciendo imposible
la consulta.

* **[TC-010-NV-01] Precision Formatting Error**: se envian `re`, `rr`, `tt` e `id` bien formados pero con precision
  decimal insuficiente, y se obtiene `N - 601` (La expresion impresa proporcionada no es valida).
    - Nota (E2E): actualmente omitido. El endpoint siempre emite `tt` con dos decimales (`toFixed(2)`).
* **[TC-011-NV-02] Mandatory Parameter Omission**: se envia la solicitud sin un parametro obligatorio (por ejemplo, `id`
  omitido por completo de la cadena) y se obtiene `N - 601`.
* **[TC-012-NV-03] Structural/Illegal Characters**: se envia la solicitud con caracteres estructuralmente invalidos (por
  ejemplo, simbolos especiales en campos RFC), falla la validacion de la cadena y se obtiene `N - 601`.
    - Nota (E2E): SAT `N - 601` actualmente aparece como `409` del endpoint porque un estado SAT distinto de `Vigente`
      bloquea la aprobacion.

---

### **4. Validaciones EFOS (advertencias por operaciones simuladas)**

Casos criticos donde el CFDI tecnicamente existe (regresa `S`), pero la API SAT retorna advertencia por operaciones
simuladas (EFOS).

* **[TC-013-EFOS-01] Flagged Issuer Identification**: CFDI encontrado (`S`), pero el Emisor esta marcado en lista EFOS.
  Retorno esperado: codigo `100`.
* **[TC-014-EFOS-02] Compound EFOS Warning**: CFDI encontrado (`S`), Emisor y un RFC de tercero estan marcados en lista
  EFOS. Retorno esperado: codigo `101` o `104`.
* **[TC-015-EFOS-03] Third-Party Only EFOS Warning**: CFDI encontrado (`S`), el Emisor NO esta marcado, pero un RFC de
  tercero si esta marcado en lista EFOS. Retorno esperado: codigo `102` o `103`.
    - Nota (E2E): la politica actual del endpoint permite aprobacion para `102`/`103`. Solo `100`, `101`, `104` se
      bloquean.

---

### Notas importantes de implementacion

- Las pruebas E2E validan respuesta de API y estado de BD (`receipt.validation`, `cfdiComprobante.sat*`).
- La semantica SAT se valida por separado en pruebas de mock-server para evitar falsos negativos por restricciones del
  endpoint.
- La validacion SAT real esta disponible como carril opcional (`RUN_REAL_SAT_TESTS=1 npm run test:sat:real`) usando XML
  fixtures de ejemplos SW.
- Las expectativas solo-mock y solo-E2E se rastrean por separado en matrices estrictas.

### Notas de deuda tecnica

- El endpoint se prueba como integracion/E2E: estado API + estado persistido en `receipt` y `cfdiComprobante`.
- El endpoint no envia `fe` a SAT (`selloUltimos8` esta hardcodeado como `null`), por eso los casos dependientes de FE
  se omiten en E2E.
- Las respuestas SAT `N - 601` por formato incorrecto actualmente terminan en endpoint `409` porque el controlador solo
  bloquea por `acuse.estado !== "Vigente"`.
- La politica EFOS del endpoint bloquea aprobacion solo para codigos `100`, `101` y `104`; codigos `102`/`103` aun
  aprueban.

---

### Matriz estricta (apendice)

| TC             | Mock Contract                  | Endpoint + DB E2E                        | Estado E2E |
|----------------|--------------------------------|------------------------------------------|------------|
| TC-001-V-01    | `S`, EFOS `200`                | `200`, `Aprobado`, SAT `Vigente`/`200`   | Realizado  |
| TC-002-V-02    | `S`, EFOS `200` con `fe`       | No alcanzable (`fe` no enviado)          | Omitido    |
| TC-003-V-03    | `S`, EFOS `201`                | `200`, `Aprobado`, SAT `Vigente`/`201`   | Realizado  |
| TC-004-NF-01   | `N - 602`                      | `409`, `Pendiente`, SAT `N - 602`        | Realizado  |
| TC-005-NF-02   | `N - 602`                      | `409`, `Pendiente`, SAT `N - 602`        | Realizado  |
| TC-006-NF-03   | `N - 602`                      | `409`, `Pendiente`, SAT `N - 602`        | Realizado  |
| TC-007-NF-04   | `N - 602`                      | `409`, `Pendiente`, SAT `N - 602`        | Realizado  |
| TC-008-NF-05   | `N - 602`                      | `409`, `Pendiente`, SAT `N - 602`        | Realizado  |
| TC-009-NF-06   | `N - 602` con `fe` invalido    | No alcanzable (`fe` no enviado)          | Omitido    |
| TC-010-NV-01   | `N - 601` por `tt` mal formado | No alcanzable (`tt` siempre 2 decimales) | Omitido    |
| TC-011-NV-02   | `N - 601`                      | `409`, `Pendiente`, SAT `N - 601`        | Realizado  |
| TC-012-NV-03   | `N - 601`                      | `409`, `Pendiente`, SAT `N - 601`        | Realizado  |
| TC-013-EFOS-01 | `S`, EFOS `100`                | `409`, `Pendiente`, EFOS `100`           | Realizado  |
| TC-014-EFOS-02 | `S`, EFOS `101` o `104`        | `409`, `Pendiente`, EFOS `101/104`       | Realizado  |
| TC-015-EFOS-03 | `S`, EFOS `102` o `103`        | `200`, `Aprobado`, EFOS `102/103`        | Realizado  |

## Plan de pruebas SAT Mock Server

Este plan valida el comportamiento del contrato SAT para `tests/services/CDFI/server/mock-server.js` sin restricciones
del endpoint.

### Alcance

- Endpoint SOAP y contrato WSDL del servicio SAT mock.
- Semantica SAT para `S`, `N - 602`, `N - 601` y codigos de advertencia EFOS.
- Validacion de expresion de consulta para `re`, `rr`, `tt`, `id`, `fe`.

### Casos de contrato SAT

- **[TC-001-V-01]** valores `re`, `rr`, `tt`, `id` validos -> `S` + EFOS `200`.
- **[TC-002-V-02]** valores `re`, `rr`, `tt`, `id`, `fe` validos -> `S` + EFOS `200`.
- **[TC-003-V-03]** valores `re`, `rr`, `tt`, `id` validos -> `S` + EFOS `201`.
- **[TC-004-NF-01]** comprobante legado/expirado -> `N - 602`.
- **[TC-005-NF-02]** UUID desconocido -> `N - 602`.
- **[TC-006-NF-03]** RFC emisor no coincide -> `N - 602`.
- **[TC-007-NF-04]** RFC receptor no coincide -> `N - 602`.
- **[TC-008-NF-05]** total no coincide -> `N - 602`.
- **[TC-009-NF-06]** FE no coincide -> `N - 602`.
- **[TC-010-NV-01]** precision decimal invalida (`tt`) -> `N - 601`.
- **[TC-011-NV-02]** falta parametro obligatorio (`id`) -> `N - 601`.
- **[TC-012-NV-03]** caracteres RFC ilegales -> `N - 601`.
- **[TC-013-EFOS-01]** emisor marcado por EFOS -> `S` + `100`.
- **[TC-014-EFOS-02]** emisor + tercero marcados por EFOS -> `S` + `101` o `104`.
- **[TC-015-EFOS-03]** solo tercero marcado por EFOS -> `S` + `102` o `103`.

### Matriz estricta (apendice)

| TC             | Alcance | SOAP esperado                          | Estado    |
|----------------|---------|----------------------------------------|-----------|
| TC-001-V-01    | Mock    | `Estado=Vigente`, `ValidacionEFOS=200` | Realizado |
| TC-002-V-02    | Mock    | `Estado=Vigente`, `ValidacionEFOS=200` | Realizado |
| TC-003-V-03    | Mock    | `Estado=Vigente`, `ValidacionEFOS=201` | Realizado |
| TC-004-NF-01   | Mock    | `CodigoEstatus` contiene `N - 602`     | Realizado |
| TC-005-NF-02   | Mock    | `CodigoEstatus` contiene `N - 602`     | Realizado |
| TC-006-NF-03   | Mock    | `CodigoEstatus` contiene `N - 602`     | Realizado |
| TC-007-NF-04   | Mock    | `CodigoEstatus` contiene `N - 602`     | Realizado |
| TC-008-NF-05   | Mock    | `CodigoEstatus` contiene `N - 602`     | Realizado |
| TC-009-NF-06   | Mock    | `CodigoEstatus` contiene `N - 602`     | Realizado |
| TC-010-NV-01   | Mock    | `CodigoEstatus` contiene `N - 601`     | Realizado |
| TC-011-NV-02   | Mock    | `CodigoEstatus` contiene `N - 601`     | Realizado |
| TC-012-NV-03   | Mock    | `CodigoEstatus` contiene `N - 601`     | Realizado |
| TC-013-EFOS-01 | Mock    | `ValidacionEFOS=100`                   | Realizado |
| TC-014-EFOS-02 | Mock    | `ValidacionEFOS in [101, 104]`         | Realizado |
| TC-015-EFOS-03 | Mock    | `ValidacionEFOS in [102, 103]`         | Realizado |

## Pruebas con SAT real (en desarrollo)

Este conjunto incluye una suite opcional de pruebas en vivo contra SAT:

- Archivo de prueba: `tests/services/CDFI/satConsultaService.e2e.test.js`
- Gate: `RUN_REAL_SAT_TESTS=1`

### Por que es opcional

Las validaciones en vivo con SAT son intencionalmente opcionales porque dependen de:

- conectividad a internet
- disponibilidad del servicio SAT
- cambios reales de estado de facturas con el tiempo

### Fuente de facturas

Fuente preferida para fixtures XML:

- `https://developers.sw.com.mx/knowledge-base/ejemplos-4-0/`

Descarga uno o mas XML CFDI de los ejemplos de SW y colocalos en:

- `tests/services/CDFI/tax_invoices(CFDIs)/real`

### Ejecucion

```zsh
NODE_OPTIONS='--experimental-vm-modules' bunx jest tests/services/CDFI/satConsultaService.e2e.test.js --runInBand --verbose --testTimeout=120000
```

### Comportamiento y aserciones

La prueba parsea cada XML (`parseCFDI`) y llama SAT (`consultarCfdiOnce`) con:

- `re` desde RFC emisor
- `rr` desde RFC receptor
- `tt` desde total
- `id` desde UUID
- `fe` desde `selloUltimos8`

Como el estado SAT depende del tiempo, las aserciones validan integridad de respuesta en lugar de forzar un solo estado:

- `codigoEstatus` inicia con `S -` o `N -`
- `estado` es un string no vacio
- `validacionEFOS` esta presente como string

### Notas

- Manten esta suite fuera del CI regular, salvo que quieras explicitamente un carril programado/manual de chequeo en
  vivo.
- Si un fixture esta mal formado, `parseCFDI` fallara antes de llamar a SAT.
- Desarrollo en proceso, no es ticket real; es un extra util para pruebas futuras.
