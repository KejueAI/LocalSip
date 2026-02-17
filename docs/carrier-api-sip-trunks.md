# Carrier API: SIP Trunks

The SIP Trunks API allows carriers to manage SIP trunks programmatically. All endpoints follow the JSON:API specification.

## Base URL

```
https://<api-subdomain>/carrier/v1/sip_trunks
```

## Authentication

All requests must be authenticated using a carrier API access token via Bearer authentication:

```
Authorization: Bearer <carrier_api_token>
```

Basic authentication is also supported (the token is passed as the password).

The request must be sent to the `api` subdomain (e.g. `api.somleng.dev`).

---

## Authentication Modes

SIP trunks support three authentication modes:

| Mode | Description |
|---|---|
| `ip_address` | The remote PBX is identified by its source IP address. No credentials are needed. |
| `client_credentials` | Somleng generates a username and password. The remote PBX registers TO Somleng using these credentials. |
| `outbound_registration` | You provide a username, password, and host. Somleng (FreeSWITCH) actively registers TO your PBX, enabling outbound calls through it. |

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
        "region": { "table": { "identifier": "ap-southeast-1", "alias": "hydrogen", "human_name": "South East Asia (Singapore)" } },
        "max_channels": 30,
        "default_sender": "1234567890",
        "inbound_country": "US",
        "inbound_source_ips": ["203.0.113.1"],
        "outbound_host": "pbx.example.com:5060",
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

#### Request Body (ip_address mode)

```json
{
  "data": {
    "type": "sip_trunk",
    "attributes": {
      "name": "My Trunk",
      "authentication_mode": "ip_address",
      "region": "hydrogen",
      "max_channels": 30,
      "inbound_country": "US",
      "inbound_source_ips": ["203.0.113.1"],
      "default_sender": "1234567890",
      "outbound_host": "pbx.example.com:5060",
      "outbound_dial_string_prefix": "+1",
      "outbound_national_dialing": false,
      "outbound_plus_prefix": true,
      "outbound_route_prefixes": ["1855"]
    }
  }
}
```

#### Request Body (outbound_registration mode)

```json
{
  "data": {
    "type": "sip_trunk",
    "attributes": {
      "name": "My PBX Registration",
      "authentication_mode": "outbound_registration",
      "region": "hydrogen",
      "username": "myuser",
      "password": "mypassword",
      "outbound_host": "pbx.example.com:5060"
    }
  }
}
```

When using `outbound_registration`, Somleng will create a FreeSWITCH gateway that actively sends SIP REGISTER to the specified `outbound_host`. Once registered, outbound calls can be routed through this trunk.

#### Attributes

| Attribute | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Name of the SIP trunk. |
| `authentication_mode` | string | Yes | Authentication method: `ip_address`, `client_credentials`, or `outbound_registration`. |
| `region` | string | Yes | Region alias where the trunk is deployed (e.g. `hydrogen`). Must match a valid `SomlengRegion::Region` alias. |
| `max_channels` | integer | No | Maximum number of concurrent channels. Must be greater than 0. |
| `inbound_country` | string | No | ISO 3166-1 alpha-2 country code for inbound calls (e.g. `US`, `KH`). |
| `inbound_source_ips` | array of strings | No | List of allowed source IPv4 addresses for inbound traffic. |
| `default_sender` | string | No | Default sender/caller ID. |
| `username` | string | Conditional | SIP username. Required for `outbound_registration`. Auto-generated for `client_credentials`. |
| `password` | string | Conditional | SIP password. Required for `outbound_registration`. Auto-generated for `client_credentials`. |
| `outbound_host` | string | Conditional | Hostname or IP (with optional port) of the outbound destination. Required for `outbound_registration`. Format: `host` or `host:port`. |
| `outbound_dial_string_prefix` | string | No | Prefix prepended to the dial string for outbound calls. |
| `outbound_national_dialing` | boolean | No | Whether to use national dialing format for outbound calls. |
| `outbound_plus_prefix` | boolean | No | Whether to prepend `+` to outbound dial strings. |
| `outbound_route_prefixes` | array of strings | No | List of number prefixes used for outbound routing. |

#### Validation Rules

- `inbound_source_ips` entries must be valid IPv4 addresses.
- `region` must match a configured region alias.
- `inbound_country` must be a valid ISO 3166-1 alpha-2 code.
- When `authentication_mode` is `outbound_registration`, `username`, `password`, and `outbound_host` are required.

#### Response

Returns the created SIP trunk. When `authentication_mode` is `client_credentials` or `outbound_registration`, the response includes `username` and `password` attributes.

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

When updating an `outbound_registration` trunk's `username`, `password`, or `outbound_host`, the FreeSWITCH gateway is automatically recreated with the new credentials.

When switching `authentication_mode` between modes, the old mode's resources are cleaned up and the new mode's resources are created.

---

### Delete a SIP Trunk

```
DELETE /carrier/v1/sip_trunks/:id
```

Deletes the SIP trunk and cleans up associated resources:
- For `outbound_registration`: removes the FreeSWITCH gateway and stops registration.
- For `client_credentials`: removes the SIP subscriber.

#### Response

Returns `204 No Content`.

---

## Conditional Response Fields

| Attribute | Condition |
|---|---|
| `username` | Only returned when `authentication_mode` is `client_credentials` or `outbound_registration`. |
| `password` | Only returned when `authentication_mode` is `client_credentials` or `outbound_registration`. |

## Error Responses

Validation errors are returned in JSON:API error format. Common errors include:

- **Invalid IP address** in `inbound_source_ips`
- **Invalid region** alias
- **Invalid country code** for `inbound_country`
- **Missing required attributes** (`name`, `authentication_mode`, `region`)
- **Missing credentials** (`username`, `password`, `outbound_host` required for `outbound_registration`)
