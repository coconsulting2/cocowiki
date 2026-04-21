# Modelo entidad-relación (PostgreSQL / Prisma)

| Metadato | Valor |
|----------|--------|
| **Versión del documento** | 1.0.1 |
| **Última actualización** | 2026-04-15 |
| **Fuente** | [schema.prisma](../../../TC3005B.501-Backend/prisma/schema.prisma) (monorepo, ruta relativa desde este repo) |

## Alcance

Este diagrama describe las tablas creadas a partir del esquema **Prisma** en **PostgreSQL** (base `CocoScheme` en desarrollo). Los archivos PDF/XML de comprobantes **no** se guardan en PostgreSQL: los campos `pdf_file_id` y `xml_file_id` de `Receipt` almacenan identificadores **ObjectId** de **MongoDB GridFS** (ver [flujos.md](flujos.md)).

## Diagrama ER (Mermaid)

```mermaid
erDiagram
    Role {
        int role_id PK
        varchar role_name UK
    }

    Department {
        int department_id PK
        varchar department_name UK
        varchar costs_center
        bool active
    }

    User {
        int user_id PK
        int role_id FK
        int department_id FK
        varchar user_name UK
        varchar password
        varchar workstation
        varchar email UK
        varchar phone_number
        float wallet
        datetime creation_date
        datetime last_mod_date
        bool active
    }

    Request_status {
        int request_status_id PK
        varchar status UK
    }

    Request {
        int request_id PK
        int user_id FK
        int request_status_id FK
        text notes
        float requested_fee
        float imposed_fee
        float request_days
        datetime creation_date
        datetime last_mod_date
        bool active
    }

    AlertMessage {
        int message_id PK
        varchar message_text
    }

    Alert {
        int alert_id PK
        int request_id FK
        int message_id FK
        datetime alert_date
    }

    Country {
        int country_id PK
        varchar country_name UK
    }

    City {
        int city_id PK
        varchar city_name UK
    }

    Route {
        int route_id PK
        int id_origin_country FK
        int id_origin_city FK
        int id_destination_country FK
        int id_destination_city FK
        int router_index
        bool plane_needed
        bool hotel_needed
        date beginning_date
        time beginning_time
        date ending_date
        time ending_time
    }

    Route_Request {
        int route_request_id PK
        int request_id FK
        int route_id FK
    }

    Receipt_Type {
        int receipt_type_id PK
        varchar receipt_type_name UK
    }

    Receipt {
        int receipt_id PK
        int receipt_type_id FK
        int request_id FK
        enum validation
        float amount
        bool refund
        datetime submission_date
        datetime validation_date
        varchar pdf_file_id
        varchar pdf_file_name
        varchar xml_file_id
        varchar xml_file_name
    }

    cfdi_comprobantes {
        int cfdi_id PK
        int receipt_id FK
        varchar uuid UK
        datetime fecha_timbrado
        varchar rfc_pac
        varchar version
        varchar serie
        varchar folio
        datetime fecha_emision
        varchar tipo_comprobante
        varchar lugar_expedicion
        varchar exportacion
        varchar metodo_pago
        varchar forma_pago
        varchar moneda
        float tipo_cambio
        float subtotal
        float descuento
        float iva
        float total
        varchar rfc_emisor
        varchar nombre_emisor
        varchar regimen_fiscal_emisor
        varchar rfc_receptor
        varchar nombre_receptor
        varchar domicilio_fiscal_receptor
        varchar regimen_fiscal_receptor
        varchar uso_cfdi
        varchar sat_codigo_estatus
        varchar sat_estado
        varchar sat_es_cancelable
        varchar sat_estatus_cancelacion
        varchar sat_validacion_efos
        datetime created_at
    }

    Role ||--o{ User : "assigned"
    Department ||--o{ User : "belongs"
    User ||--o{ Request : "creates"
    Request_status ||--o{ Request : "state"
    Request ||--o{ Alert : "triggers"
    AlertMessage ||--o{ Alert : "template"
    Request ||--o{ Route_Request : "includes"
    Route ||--o{ Route_Request : "segment"
    Country ||--o{ Route : "origin_country"
    Country ||--o{ Route : "destination_country"
    City ||--o{ Route : "origin_city"
    City ||--o{ Route : "destination_city"
    Receipt_Type ||--o{ Receipt : "type"
    Request ||--o{ Receipt : "expense_proof"
    Receipt ||--o| cfdi_comprobantes : "zero_or_one_cfdi"
```

## Enum `ValidationStatus` (columna `Receipt.validation`)

Valores en base de datos (Prisma): `Pendiente`, `Aprobado`, `Rechazado`.

## Relación 1:0..1 `Receipt` ↔ `cfdi_comprobantes`

- Cada fila en `cfdi_comprobantes` exige un `receipt_id` único (una factura CFDI por comprobante).
- Un `Receipt` puede existir **sin** registro CFDI hasta que se registre vía API (ver `POST /api/comprobantes/:receipt_id`).

## Archivos binarios (fuera del ER relacional)

| Columna | Destino real |
|---------|----------------|
| `Receipt.pdf_file_id`, `Receipt.xml_file_id` | ObjectId en **MongoDB GridFS** (bucket por defecto del driver). |
| `pdf_file_name`, `xml_file_name` | Metadato en PostgreSQL para nombre legible. |

> **GitHub Pages:** el sitio publica solo `cocowiki/docs`. El enlace a `schema.prisma` usa ruta relativa al monorepo; si solo clonaste el repo de la wiki, abre el backend en el repo del producto.
