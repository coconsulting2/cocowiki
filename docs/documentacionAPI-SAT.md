# SAT — Validación de CFDI para CocoAPI

**Este archivo es la referencia canónica** para Consulta de Estado de CFDI (M1-002, M1-003, M1-009, M1-011, NT-009).  
El backend del curso TC3005B mantiene un resumen enlazado en [`TC3005B.501-Backend/middleware/validate.md`](../../TC3005B.501-Backend/middleware/validate.md) (misma cadena `expresionImpresa` y mismos headers).

---

## Contexto del producto

CocoAPI valida comprobantes fiscales (CFDI) cuando un empleado sube una factura como gasto de viaje. US-03 del backlog exige que **no se pueda aprobar un reembolso con CFDI inválido o cancelado**. Para eso se consulta al SAT y se persiste el resultado (ver [mapeo a base de datos](#mapeo-a-base-de-datos)).

---

## Servicio a usar: Consulta de Estado de CFDI (no Descarga Masiva)

El SAT expone varios web services. **CocoAPI solo usa uno**: el de Consulta de Estado. Cualquier otro servicio del SAT que aparezca en documentación (Descarga Masiva, Verificación de Descarga Masiva, Autenticación con e.firma) **no aplica** a este producto y no debe integrarse sin discusión previa con el equipo.

| Aspecto | Consulta de Estado (la que usamos) | Descarga Masiva (no usar) |
|---|---|---|
| Autenticación | Pública, sin credenciales | Requiere e.firma del contribuyente |
| Entrada | RFC emisor, RFC receptor, total, UUID (+ sello `fe` si aplica) | Solicitud firmada con certificado |
| Salida | Vigente / Cancelado / No Encontrado | Paquetes ZIP con XML masivos |
| Propósito | Validar 1 CFDI puntual | Descargar histórico de CFDI |
| Uso en CocoAPI | M1-009 | No aplica |

---

## Endpoint y método SOAP

**WSDL:**

```
https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc?wsdl
```

**Endpoint del servicio:**

```
https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc
```

**Método:** `Consulta(expresionImpresa)`  
**SOAPAction:** `http://tempuri.org/IConsultaCFDIService/Consulta`  
**Content-Type:** `text/xml;charset="utf-8"`

---

## Parámetro `expresionImpresa` (contrato único)

Es un string con formato **query string** (como en el código QR de la representación impresa), armado con datos del CFDI:

**Forma completa (recomendada; coincide con representación impresa / QR):**

```
?re={RFC_EMISOR}&rr={RFC_RECEPTOR}&tt={TOTAL}&id={UUID}&fe={SELLO}
```

| Parámetro | Significado | Origen típico en el XML |
|---|---|---|
| `re` | RFC del emisor | `cfdi:Emisor@Rfc` |
| `rr` | RFC del receptor | `cfdi:Receptor@Rfc` |
| `tt` | Total con **punto** decimal y al menos 2 decimales (ej. `1160.00`) | `cfdi:Comprobante@Total` |
| `id` | UUID del timbre (folio fiscal) | `tfd:TimbreFiscalDigital@UUID` |
| `fe` | Últimos **8 caracteres** del sello digital del **emisor** (`Sello` del comprobante, base64) | `cfdi:Comprobante@Sello` (recortar) |

**Forma mínima (solo `re`, `rr`, `tt`, `id`):** algunas integraciones y pruebas omiten `fe`. El SAT puede responder; si obtienes `N - 601` (expresión inválida), verifica totales/decimales, encoding y si el servicio exige `fe` para ese comprobante.

Los datos anteriores son los que M1-002 (parser XML) debe exponer para armar la cadena antes de llamar al servicio.

---

## Respuesta del servicio (acuse)

| Campo | Descripción |
|---|---|
| `CodigoEstatus` | Resultado general. Suele empezar por `S - …` (éxito al resolver la consulta) o `N - 601: …` / `N - 602: …` (expresión inválida / no encontrado). **No confundir** el número 601/602 con “cancelado”: cancelación fiscal va en `Estado`. |
| `Estado` | **Vigente** / **Cancelado** / **No Encontrado** — valor principal para reglas de negocio y UI. |
| `EsCancelable` | Si el comprobante puede cancelarse (p. ej. `Cancelable con aceptación`, `No cancelable`). Puede ir vacío cuando no aplica. |
| `EstatusCancelacion` | Paso del proceso de cancelación si aplica (`En proceso`, `Cancelado sin aceptación`, etc.). |
| `ValidacionEFOS` | Código de lista EFOS del SAT sobre el emisor y RFCs de terceros (ver tabla abajo). |

### `CodigoEstatus` (patrones habituales)

- `S - Comprobante obtenido satisfactoriamente.` — la consulta se resolvió; revisar `Estado` (puede ser **Vigente** o **Cancelado**).
- `N - 601: La expresión impresa proporcionada no es válida.` — formato incorrecto o datos inconsistentes; `Estado` suele ser **No Encontrado**.
- `N - 602: Comprobante no encontrado.` — no hay registro con ese UUID en las bases consultadas; `Estado` suele ser **No Encontrado**.

### `ValidacionEFOS`

| Código | Significado |
|--------|-------------|
| `200` | Emisor no está en lista EFOS |
| `201` | Emisor y ningún RFC a cuenta de terceros en EFOS |
| `100` | Emisor sí está en EFOS |
| `101` | Emisor y algún RFC a cuenta de terceros en EFOS |
| `102` | Emisor no en EFOS; un RFC a cuenta de terceros sí |
| `103` | Emisor no en EFOS; alguno de varios RFC de terceros sí |
| `104` | Emisor y alguno de varios RFC de terceros en EFOS |
| *(vacío)* | No se pudo validar (p. ej. N-601 / N-602) |

---

## Mapeo a base de datos

**Diseño objetivo (CocoAPI / backlog):** `cfdi_comprobantes.estatus_sat` como ENUM (`VIGENTE`, `CANCELADO`, `NO_ENCONTRADO`, `PENDIENTE_VALIDACION`, …), más `fecha_validacion_sat`, `respuesta_sat_raw` opcional.

**Implementación actual en TC3005B (Prisma):** tabla `cfdi_comprobantes` con columnas `sat_estado`, `sat_codigo_estatus`, `sat_es_cancelable`, `sat_estatus_cancelacion`, `sat_validacion_efos` — los textos de **`Estado`** y **`CodigoEstatus`** se guardan tal cual los devuelve el SAT (p. ej. `Vigente`, `No Encontrado`). Hasta que exista migración al ENUM unificado, el código y las validaciones deben usar **los mismos literales que el SAT** o una capa de mapeo explícita.

| `Estado` del SAT | Regla de negocio CocoAPI |
|---|---|
| `Vigente` | Permitir flujo de aprobación (tras validar EFOS según política). |
| `Cancelado` | Bloquear reembolso; mensaje al usuario. |
| `No Encontrado` | Bloquear reembolso; pedir revisar datos / UUID. |

---

## Ejemplos SOAP sin librería (HTTP raw)

Misma `expresionImpresa` en todos los ejemplos; sustituir placeholders.

**cURL**

```bash
curl --request POST \
  --url https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc \
  --header 'Content-Type: text/xml;charset="utf-8"' \
  --header 'SOAPAction: http://tempuri.org/IConsultaCFDIService/Consulta' \
  --data '
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
  <soapenv:Header/>
  <soapenv:Body>
    <tem:Consulta>
      <tem:expresionImpresa><![CDATA[?re=RFC_EMISOR&rr=RFC_RECEPTOR&tt=TOTAL&id=UUID&fe=SELLO_8_CHARS]]></tem:expresionImpresa>
    </tem:Consulta>
  </soapenv:Body>
</soapenv:Envelope>'
```

**fetch**

```typescript
const body = `
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
  <soapenv:Header/>
  <soapenv:Body>
    <tem:Consulta>
      <tem:expresionImpresa><![CDATA[?re=RFC_EMISOR&rr=RFC_RECEPTOR&tt=TOTAL&id=UUID&fe=SELLO_8_CHARS]]></tem:expresionImpresa>
    </tem:Consulta>
  </soapenv:Body>
</soapenv:Envelope>
`;

fetch("https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc", {
  method: "POST",
  headers: {
    "Content-Type": 'text/xml;charset="utf-8"',
    SOAPAction: "http://tempuri.org/IConsultaCFDIService/Consulta",
  },
  body,
})
  .then((res) => res.text())
  .then(console.log)
  .catch(console.error);
```

**axios** (forzar cuerpo sin transformar)

```typescript
import axios from "axios";

const body = `
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
  <soapenv:Header/>
  <soapenv:Body>
    <tem:Consulta>
      <tem:expresionImpresa><![CDATA[?re=RFC_EMISOR&rr=RFC_RECEPTOR&tt=TOTAL&id=UUID&fe=SELLO_8_CHARS]]></tem:expresionImpresa>
    </tem:Consulta>
  </soapenv:Body>
</soapenv:Envelope>
`;

axios.post(
  "https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc",
  body,
  {
    headers: {
      "Content-Type": 'text/xml;charset="utf-8"',
      SOAPAction: "http://tempuri.org/IConsultaCFDIService/Consulta",
    },
    responseType: "text",
    transformRequest: [(data) => data],
  }
).then((res) => console.log(res.data)).catch(console.error);
```

### Ejemplos de XML de respuesta

**Éxito — comprobante vigente**

```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <ConsultaResponse xmlns="http://tempuri.org/">
      <ConsultaResult xmlns:a="http://schemas.datacontract.org/2004/07/Sat.Cfdi.Negocio.ConsultaCfdi.Servicio"
                        xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <a:CodigoEstatus>S - Comprobante obtenido satisfactoriamente.</a:CodigoEstatus>
        <a:EsCancelable>Cancelable con aceptación</a:EsCancelable>
        <a:Estado>Vigente</a:Estado>
        <a:EstatusCancelacion/>
        <a:ValidacionEFOS>200</a:ValidacionEFOS>
      </ConsultaResult>
    </ConsultaResponse>
  </s:Body>
</s:Envelope>
```

**Expresión inválida (601)**

```xml
<a:CodigoEstatus>N - 601: La expresión impresa proporcionada no es válida.</a:CodigoEstatus>
<a:Estado>No Encontrado</a:Estado>
```

**No encontrado (602)**

```xml
<a:CodigoEstatus>N - 602: Comprobante no encontrado.</a:CodigoEstatus>
<a:Estado>No Encontrado</a:Estado>
```

*(Los envelopes completos son análogos al ejemplo “vigente”; el SAT puede variar ligeramente el texto exacto de `CodigoEstatus`.)*

---

## Stack técnico (backend TC3005B / CocoAPI)

- **Framework:** Express.js (proyecto actual en **JavaScript** ESM; un servicio dedicado puede nombrarse `satValidationService.js` o `.ts` si migran a TypeScript).
- **Cliente SOAP:** paquete npm [`soap`](https://github.com/vpulim/node-soap) o `strong-soap` como alternativa.

### Instalación

```bash
npm install soap
# o
npm install strong-soap
```

### Esqueleto del servicio (TypeScript; adaptable a `.js`)

```typescript
import * as soap from "soap";

const SAT_WSDL =
  process.env.SAT_WSDL_URL ||
  "https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc?wsdl";

export type EstatusSAT = "VIGENTE" | "CANCELADO" | "NO_ENCONTRADO" | "ERROR";

interface ValidacionSATInput {
  rfcEmisor: string;
  rfcReceptor: string;
  total: number;
  uuid: string;
  /** Últimos 8 caracteres del Sello del comprobante; opcional según política de armado de cadena */
  selloEmisorUltimos8?: string;
}

interface ValidacionSATResult {
  estatus: EstatusSAT;
  esCancelable?: string;
  estatusCancelacion?: string;
  validacionEFOS?: string;
  raw: unknown;
  fechaConsulta: Date;
}

function buildExpresionImpresa(input: ValidacionSATInput): string {
  const tt = input.total.toFixed(2);
  const base = `?re=${input.rfcEmisor}&rr=${input.rfcReceptor}&tt=${tt}&id=${input.uuid}`;
  return input.selloEmisorUltimos8 ? `${base}&fe=${input.selloEmisorUltimos8}` : base;
}

export async function validarCFDI(input: ValidacionSATInput): Promise<ValidacionSATResult> {
  const expresionImpresa = buildExpresionImpresa(input);
  const client = await soap.createClientAsync(SAT_WSDL);
  const [response] = await client.ConsultaAsync({ expresionImpresa });

  const estado = response?.ConsultaResult?.Estado ?? "";
  const estatus: EstatusSAT =
    estado === "Vigente"
      ? "VIGENTE"
      : estado === "Cancelado"
        ? "CANCELADO"
        : estado === "No Encontrado"
          ? "NO_ENCONTRADO"
          : "ERROR";

  return {
    estatus,
    esCancelable: response?.ConsultaResult?.EsCancelable,
    estatusCancelacion: response?.ConsultaResult?.EstatusCancelacion,
    validacionEFOS: response?.ConsultaResult?.ValidacionEFOS,
    raw: response,
    fechaConsulta: new Date(),
  };
}
```

**Nota:** la forma exacta de `response` depende de la versión de `soap` y del WSDL; validar en runtime o con una llamada de prueba.

**Variable `SAT_WSDL_URL`:** permite apuntar al mock de NT-009 en pruebas:

- Desarrollo/CI: `SAT_WSDL_URL=http://localhost:3099/sat-mock?wsdl`
- Producción: omitir o vacío para usar el SAT real.

---

## Resiliencia (obligatorio en producción)

El servicio del SAT tiene downtime. **No asumir Vigente si el SAT no responde** — eso rompería US-03.

1. **Reintentos con backoff** — por ejemplo 3 intentos: 1s, 2s, 4s.
2. **Timeout** — por ejemplo 10s por intento.
3. **Cache corta** — p. ej. 24h si el resultado fue `Vigente` (el estatus cambia con poca frecuencia).
4. **Estado `PENDIENTE_VALIDACION`** — si tras reintentos no hay respuesta, no aprobar reembolso hasta tener acuse real; cola/cron según arquitectura.
5. **Nunca** fallback automático a “Vigente” sin respuesta del SAT.

---

## Integración con el mock de pruebas (NT-009)

Mock NT-009 debe simular respuestas con la misma forma de campos que el SAT real (`CodigoEstatus`, `Estado`, `ValidacionEFOS`, etc.). Casos típicos de prueba:

- `CodigoEstatus` tipo **S** + `Estado=Vigente` + `ValidacionEFOS=200` — caso feliz.
- `CodigoEstatus` tipo **S** + `Estado=Cancelado` — bloqueo por cancelación fiscal.
- `CodigoEstatus` **N - 601** o **N - 602** + `Estado=No Encontrado` — expresión inválida o UUID inexistente.

**Jest:** `jest.mock('soap')` o cliente apuntando al mock.  
**E2E:** `SAT_WSDL_URL=http://localhost:3099/sat-mock?wsdl` (u host que defina NT-009).

---

## Checklist por card del Módulo 1

### M1-002 — Parser XML CFDI

- [ ] Extraer `Emisor@Rfc`, `Receptor@Rfc`, `Comprobante@Total`, `TimbreFiscalDigital@UUID`, y **últimos 8 caracteres** de `Comprobante@Sello` para `fe`.
- [ ] Soportar CFDI v3.3 y v4.0 (namespaces).
- [ ] Validar formato de UUID antes de llamar al SAT.

### M1-003 — POST /comprobantes

- [ ] Persistir resultado SAT (objetivo: `estatus_sat` + timestamps; hoy: columnas `sat_*` en Prisma hasta migración).
- [ ] Encolar o invocar validación SAT según diseño (síncrono vs `PENDIENTE_VALIDACION`).
- [ ] UUID duplicado → 409 Conflict.

### M1-009 — Validación SAT

- [ ] Cliente SOAP + armado de `expresionImpresa` (con o sin `fe`, documentado).
- [ ] Retry, timeout, cache opcional.
- [ ] Actualizar columnas de acuse en `cfdi_comprobantes`.
- [ ] Bloquear aprobación de reembolsos si el CFDI no está **Vigente** según última consulta válida.
- [ ] Errores de red / timeout sin marcar como vigente por defecto.

### M1-011 — Badge frontend

- [ ] Estados visibles: vigente / cancelado / no encontrado / pendiente (si aplica).
- [ ] Re-verificación manual si se expone `GET …/validacion-sat` (según API final).

### NT-009 — Mock SAT

- [ ] Mock standalone + wrapper Jest + README.

---

## Fuentes oficiales y utilidad

- Portal público de verificación: https://verificacfdi.facturaelectronica.sat.gob.mx/
- WSDL: https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc?wsdl
- Endpoint: https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc
- Anexo 20 (CFDI): https://www.sat.gob.mx/consultas/35025/formato-de-factura-electronica-(anexo-20)
- Referencia comunitaria (CfdiUtils): https://cfdiutils.readthedocs.io/es/latest/componentes/estado-sat.html

---

## Nota sobre Descarga Masiva

El **Servicio de Verificación de Descarga Masiva de CFDI** (PDF SAT, etc.) sirve para descargas masivas firmadas con **e.firma**. **No es** el servicio de Consulta de Estado descrito aquí. Una integración futura de “descargar todo el mes” sería épica aparte (credenciales, almacén seguro, WS-Security), no parte de M1-009.
