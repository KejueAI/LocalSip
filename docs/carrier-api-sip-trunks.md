# Carrier API: SIP Trunks

The SIP Trunks API allows carriers to manage SIP trunks programmatically. All endpoints follow the JSON:API specification.

## Base URL

```
https://<api-subdomain>/carrier/v1/sip_trunks
```

## Authentication

All requests must be authenticated using carrier credentials.

---

## Endpoints

### List SIP Trunks

```
GET /carrier/v1/sip_trunks
```

Returns all SIP trunks belonging to the authenticated carrier.

#### Response

```json
{
  "data": [
    {
      "id": "trunk-id",
      "type": "sip_trunk",
      "attributes": {
        "name": "My Trunk",
        "authentication_mode": "ip_address",
        "region": "us-east-1",
        "max_channels": 30,
        "default_sender": "1234567890",
        "inbound_country": "US",
        "inbound_source_ips": ["203.0.113.1"],
        "outbound_host": "pbx.example.com",
        "outbound_dial_string_prefix": null,
        "outbound_national_dialing": false,
        "outbound_plus_prefix": false,
        "outbound_route_prefixes": []
      }
    }
  ]
}
```

---

### Create a SIP Trunk

```
POST /carrier/v1/sip_trunks
```

#### Request Body

```json
{
  "data": {
    "type": "sip_trunk",
    "attributes": {
      "name": "My Trunk",
      "authentication_mode": "ip_address",
      "region": "us-east-1",
      "max_channels": 30,
      "inbound_country": "US",
      "inbound_source_ips": ["203.0.113.1"],
      "default_sender": "1234567890",
      "outbound_host": "pbx.example.com",
      "outbound_dial_string_prefix": "+1",
      "outbound_national_dialing": false,
      "outbound_plus_prefix": true,
      "outbound_route_prefixes": ["1855"]
    }
  }
}
```

#### Attributes

| Attribute | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Name of the SIP trunk. |
| `authentication_mode` | string | Yes | Authentication method. Must be a valid `SIPTrunk.authentication_mode` value (e.g. `ip_address`, `client_credentials`). |
| `region` | string | Yes | Region alias where the trunk is deployed. Must match a valid `SomlengRegion::Region` alias. |
| `max_channels` | integer | No | Maximum number of concurrent channels. Must be greater than 0. |
| `inbound_country` | string | No | ISO 3166-1 alpha-2 country code for inbound calls (e.g. `US`, `KH`). |
| `inbound_source_ips` | array of strings | No | List of allowed source IPv4 addresses for inbound traffic. |
| `default_sender` | string | No | Default sender/caller ID. |
| `outbound_host` | string | No | Hostname or IP of the outbound destination (e.g. a PBX). |
| `outbound_dial_string_prefix` | string | No | Prefix prepended to the dial string for outbound calls. |
| `outbound_national_dialing` | boolean | No | Whether to use national dialing format for outbound calls. |
| `outbound_plus_prefix` | boolean | No | Whether to prepend `+` to outbound dial strings. |
| `outbound_route_prefixes` | array of strings | No | List of number prefixes used for outbound routing. |

#### Validation Rules

- `inbound_source_ips` entries must be valid IPv4 addresses.
- `region` must match a configured region alias.
- `inbound_country` must be a valid ISO 3166-1 alpha-2 code.

#### Response

Returns the created SIP trunk. When `authentication_mode` is `client_credentials`, the response includes `username` and `password` attributes.

---

### Get a SIP Trunk

```
GET /carrier/v1/sip_trunks/:id
```

#### Response

Returns the SIP trunk with the given ID.

---

### Update a SIP Trunk

```
PATCH /carrier/v1/sip_trunks/:id
```

#### Request Body

```json
{
  "data": {
    "type": "sip_trunk",
    "id": "trunk-id",
    "attributes": {
      "name": "Updated Trunk Name"
    }
  }
}
```

All attributes are optional on update. The same validation rules from creation apply. Only the provided attributes are updated.

---

### Delete a SIP Trunk

```
DELETE /carrier/v1/sip_trunks/:id
```

Deletes the SIP trunk and cleans up associated resources.

#### Response

Returns the deleted SIP trunk resource.

---

## Conditional Response Fields

| Attribute | Condition |
|---|---|
| `username` | Only returned when `authentication_mode` is `client_credentials`. |
| `password` | Only returned when `authentication_mode` is `client_credentials`. |

## Error Responses

Validation errors are returned in JSON:API error format. Common errors include:

- **Invalid IP address** in `inbound_source_ips`
- **Invalid region** alias
- **Invalid country code** for `inbound_country`
- **Missing required attributes** (`name`, `authentication_mode`, `region`)
