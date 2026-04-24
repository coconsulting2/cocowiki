# NT-010: Plan de Pruebas E2E — Servicio de Tipo de Cambio (Banxico Exchange Rate: BER)

**Versión:** 1.0  
**Última actualización:** 2026-04-22  
**Archivo fuente:** `tests/services/BER/exchangeRate.e2e.test.js`  
**Alcance:** Validación E2E del endpoint de tipo de cambio con cache en MongoDB y mock local de Banxico
---

## 1. Objetivo

Este documento refleja el suite real `exchangeRate.e2e.test.js` después de renumerar los IDs para que no existan gaps.
La meta es que la documentación y la implementación tengan el mismo inventario de casos, el mismo orden lógico y los
mismos títulos.
El suite valida:

- `GET /api/exchange-rate/rate`
- `POST /api/exchange-rate/convert`
- `GET /api/exchange-rate/history`
- `GET /api/exchange-rate/currencies`
- Persistencia y lectura de cache en MongoDB
- Manejo de errores y fallback hacia `DOF`
- Validación de entrada para códigos de moneda y montos

---

## 2. Convención de IDs

Los IDs siguen este formato:

`TC-XXX-CATEGORIA-NN`

| Parte       | Significado                              |
|-------------|------------------------------------------|
| `TC`        | Test Case                                |
| `XXX`       | Número correlativo del suite, sin saltos |
| `CATEGORIA` | Área funcional cubierta por el caso      |
| `NN`        | Orden del caso dentro de su categoría    |

### Ejemplo

`TC-026-ENDPOINT-01` significa:

- `TC`: test case
- `026`: caso número 26 del suite
- `ENDPOINT`: categoría de validación HTTP
- `01`: primer caso de esa categoría

---

## 3. Resumen del suite actual

- **Describe blocks activos:** 6
- **Tests activos:** 30
- **Bloques parametrizados (`it.each`):** 3
    - conversión de moneda: 2 casos
    - cache por par de monedas: 1 caso
    - validación de códigos inválidos: 14 casos
- **Tests omitidos o `skip`:** ninguno

### 3.1 Qué significa cada categoría

| Categoría | Significado             | Qué valida                                        |
|-----------|-------------------------|---------------------------------------------------|
| V         | Valid / Happy Path      | Casos exitosos con datos válidos                  |
| NF        | Not Found / Unavailable | Respuestas vacías o indisponibilidad de la fuente |
| ERR       | Error / Fallback        | Fallback automático y errores compuestos          |
| CACHE     | Cache Behavior          | Persistencia, reuso y expiración por día          |
| VALID     | Input Validation        | Rechazo de entradas inválidas                     |
| ENDPOINT  | Endpoint Validation     | Contrato HTTP de los endpoints expuestos          |

### 3.2 Cobertura por categoría

| Categoría |  Casos |
|-----------|-------:|
| V         |      4 |
| NF        |      1 |
| ERR       |      2 |
| CACHE     |      3 |
| VALID     |     15 |
| ENDPOINT  |      5 |
| **Total** | **30** |

---

## 4. Casos de prueba documentados

## 4.1 Categoría V — Happy Path

| ID            | Título                                                          | Qué verifica                                                |
|---------------|-----------------------------------------------------------------|-------------------------------------------------------------|
| `TC-001-V-01` | GET /api/exchange-rate/rate returns successful response         | Respuesta exitosa de la tasa USD/MXN con `fromCache: false` |
| `TC-002-V-02` | Cache persists in MongoDB and is retrieved on second call       | Cache diario guardado y reutilizado en una segunda llamada  |
| `TC-003-V-03` | POST /api/exchange-rate/convert calculates conversion correctly | Conversión correcta para `amount = 100`                     |
| `TC-004-V-04` | POST /api/exchange-rate/convert calculates conversion correctly | Conversión correcta para `amount = 1892.98`                 |

### Validaciones comunes de la categoría V

- `statusCode === 200`
- `success === true`
- respuesta con `data`
- `rate` numérico
- `source === "DOF"`
- `fromCache` según corresponda

---

## 4.2 Categoría NF — Not Found / Unavailable

| ID             | Título                       | Qué verifica                                            |
|----------------|------------------------------|---------------------------------------------------------|
| `TC-005-NF-01` | Banxico returns empty series | El mock devuelve serie vacía y el endpoint responde 500 |

### Validaciones

- `statusCode === 500`
- `success === false`
- `error === "Both Wise and DOF APIs failed: No rate data returned from DOF API"`

---

## 4.3 Categoría ERR — Error / Fallback

| ID              | Título                                         | Qué verifica                                    |
|-----------------|------------------------------------------------|-------------------------------------------------|
| `TC-006-ERR-01` | Fallback to DOF occurs on network error        | Banxico falla por red y se usa DOF              |
| `TC-007-ERR-02` | HTTP 500 when both APIs completely unavailable | Banxico y DOF fallan y el endpoint devuelve 500 |

### Validaciones

- `TC-006-ERR-01` debe devolver `200` y `source === "DOF"`
- `TC-007-ERR-02` debe devolver `500` con el error compuesto esperado

---

## 4.4 Categoría CACHE — Cache Behavior

| ID                | Título                                                   | Qué verifica                                               |
|-------------------|----------------------------------------------------------|------------------------------------------------------------|
| `TC-008-CACHE-01` | First call: fromCache false; Second call: fromCache true | Primera llamada guarda cache, segunda llamada lo reutiliza |
| `TC-009-CACHE-02` | Cache expires at end of day                              | El cache cambia cuando cambia la fecha simulada            |
| `TC-010-CACHE-03` | Different currency pairs have separate cache entries     | El cache se separa por par de monedas                      |

### Validaciones

- `exchange_rates` debe guardar documentos por `{ source, target, date }`
- `fromCache` cambia de `false` a `true` cuando corresponde
- no se comparte cache entre pares distintos

---

## 4.5 Categoría VALID — Input Validation

| ID                | Título                                                    | Qué verifica                     |
|-------------------|-----------------------------------------------------------|----------------------------------|
| `TC-011-VALID-01` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `A / USD`       |
| `TC-012-VALID-02` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `XX / MXN`      |
| `TC-013-VALID-03` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `AB / USD`      |
| `TC-014-VALID-04` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `WXW / MXN`     |
| `TC-015-VALID-05` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `123 / USD`     |
| `TC-016-VALID-06` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `900 / MXN`     |
| `TC-017-VALID-07` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `NXM / USD`     |
| `TC-018-VALID-08` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `USD / A`       |
| `TC-019-VALID-09` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `MXN / XX`      |
| `TC-020-VALID-10` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `USD / AB`      |
| `TC-021-VALID-11` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `MXN / WXW`     |
| `TC-022-VALID-12` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `USD / 123`     |
| `TC-023-VALID-13` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `MXN / 900`     |
| `TC-024-VALID-14` | Invalid currency codes are rejected (endpoint validation) | Rechazo del caso `USD / NXM`     |
| `TC-025-VALID-15` | Negative or zero amount in convert is rejected            | Rechazo de monto negativo o cero |

### Validaciones

- `statusCode === 400`
- la respuesta contiene `errors`

---

## 4.6 Categoría ENDPOINT — Endpoint Validation

| ID                   | Título                                                       | Qué verifica                               |
|----------------------|--------------------------------------------------------------|--------------------------------------------|
| `TC-026-ENDPOINT-01` | GET /api/exchange-rate/rate with valid params returns 200    | Contrato HTTP del endpoint de tasa         |
| `TC-027-ENDPOINT-02` | POST /api/exchange-rate/convert with valid amount            | Contrato HTTP del endpoint de conversión   |
| `TC-028-ENDPOINT-03` | POST /api/exchange-rate/convert without amount returns 400   | Validación de request sin amount           |
| `TC-029-ENDPOINT-04` | GET /api/exchange-rate/history with date range               | Respuesta de histórico por rango de fechas |
| `TC-030-ENDPOINT-05` | GET /api/exchange-rate/currencies (public, no auth required) | Endpoint público sin autenticación         |

### Validaciones

- `statusCode` esperado según cada caso
- estructura de `success`, `data`, `message` o `errors`
- `GET /api/exchange-rate/currencies` no requiere Authorization

---

## 5. Matriz de cumplimiento actual

| TC                 | Categoría | Título actual                                                   | Estado |
|--------------------|-----------|-----------------------------------------------------------------|--------|
| TC-001-V-01        | V         | GET /api/exchange-rate/rate returns successful response         | Activo |
| TC-002-V-02        | V         | Cache persists in MongoDB and is retrieved on second call       | Activo |
| TC-003-V-03        | V         | POST /api/exchange-rate/convert calculates conversion correctly | Activo |
| TC-004-V-04        | V         | POST /api/exchange-rate/convert calculates conversion correctly | Activo |
| TC-005-NF-01       | NF        | Banxico returns empty series                                    | Activo |
| TC-006-ERR-01      | ERR       | Fallback to DOF occurs on network error                         | Activo |
| TC-007-ERR-02      | ERR       | HTTP 500 when both APIs completely unavailable                  | Activo |
| TC-008-CACHE-01    | CACHE     | First call: fromCache false; Second call: fromCache true        | Activo |
| TC-009-CACHE-02    | CACHE     | Cache expires at end of day                                     | Activo |
| TC-010-CACHE-03    | CACHE     | Different currency pairs have separate cache entries            | Activo |
| TC-011-VALID-01    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-012-VALID-02    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-013-VALID-03    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-014-VALID-04    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-015-VALID-05    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-016-VALID-06    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-017-VALID-07    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-018-VALID-08    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-019-VALID-09    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-020-VALID-10    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-021-VALID-11    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-022-VALID-12    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-023-VALID-13    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-024-VALID-14    | VALID     | Invalid currency codes are rejected (endpoint validation)       | Activo |
| TC-025-VALID-15    | VALID     | Negative or zero amount in convert is rejected                  | Activo |
| TC-026-ENDPOINT-01 | ENDPOINT  | GET /api/exchange-rate/rate with valid params returns 200       | Activo |
| TC-027-ENDPOINT-02 | ENDPOINT  | POST /api/exchange-rate/convert with valid amount               | Activo |
| TC-028-ENDPOINT-03 | ENDPOINT  | POST /api/exchange-rate/convert without amount returns 400      | Activo |
| TC-029-ENDPOINT-04 | ENDPOINT  | GET /api/exchange-rate/history with date range                  | Activo |
| TC-030-ENDPOINT-05 | ENDPOINT  | GET /api/exchange-rate/currencies (public, no auth required)    | Activo |

---

## 6. Notas de implementación relevantes para la documentación

- La suite usa una fecha fija para resultados deterministas.
- El cache se valida contra `exchange_rates` con la llave `{ source, target, date }`.
- El endpoint de monedas soportadas es público.
- La suite no contiene `it.skip`.
- El texto del error todavía usa la terminología heredada de “Wise” en algunos mensajes; la documentación mantiene el
  comportamiento real del código.

---

## 7. Deuda técnica que sigue vigente

1. **Terminología heredada de “Wise” en mensajes de error y nomenclatura interna.**
    - Impacto: los mensajes no siempre coinciden con el dominio Banxico/DOF.
    - Alcance: service, controller y tests/documentación.
2. **Cache diario sin TTL de base de datos.**
    - El cache depende de la llave por fecha y de la limpieza del suite, no de un índice TTL automático.
    - Impacto: la expiración real depende de la lógica de aplicación.
3. **El histórico sigue validado solo para USD/MXN.**
    - Impacto: otros pares no están cubiertos por el suite actual.
    - Alcance: endpoint `/api/exchange-rate/history` y service asociado.
