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

## Platform Architecture

### Entity Hierarchy

```
Carrier (Your Platform)
├── SIP Trunks (shared or dedicated)
├── Phone Number Inventory
│
├── Account A (Business Customer)
│   ├── Incoming Phone Numbers (with voice_url, sip_domain)
│   ├── Phone Calls (inbound & outbound)
│   └── Optional: dedicated SIP trunk
│
├── Account B (Another Business)
│   ├── Incoming Phone Numbers
│   ├── Phone Calls
│   └── Uses shared carrier trunks
│
└── Account C (Sub-Account)
    └── Managed by carrier or parent account
```

### Key Concepts

- **Carrier**: Your platform. Owns all infrastructure (SIP trunks, phone number inventory, rate tables).
- **Account**: A business customer on your platform. Each account is fully isolated — its own phone numbers, call records, API credentials, and billing.
- **SIP Trunk**: A connection to an external SIP provider or PBX. Can be shared across all accounts or dedicated to a single account.
- **Phone Number**: A number in your inventory (e.g. `+14155551234`). Available to be assigned to accounts.
- **Incoming Phone Number**: A phone number assigned to a specific account, configured with a `voice_url` (webhook) or `sip_domain` for call routing.

---

## Multi-Tenant Setup for Multiple Businesses

Each business on your platform gets its own **Account**. Accounts provide full isolation:

| Concern | Isolation |
|---|---|
| Phone numbers | Each account owns its assigned numbers |
| Call records | Calls are tagged with `account_id` |
| API access | Each account has its own `auth_token` |
| Billing | Per-account CDRs and charges |
| Webhooks | Each number has its own `voice_url` |

### Trunk Sharing Patterns

**Pattern 1: Shared Trunks (Most Common)**

All accounts share the carrier's SIP trunks. Outbound routing is determined by `outbound_route_prefixes` on each trunk.

```
Carrier
├── SIP Trunk "US Provider"  (route_prefixes: ["1"])
├── SIP Trunk "UK Provider"  (route_prefixes: ["44"])
├── SIP Trunk "Default"      (route_prefixes: [])  ← fallback
│
├── Account "Business A" → uses shared trunks
├── Account "Business B" → uses shared trunks
└── Account "Business C" → uses shared trunks
```

**Pattern 2: Dedicated Trunk**

An account can have a dedicated SIP trunk assigned via `account.sip_trunk_id`. All outbound calls for that account go through its dedicated trunk.

```
Carrier
├── SIP Trunk "Shared" (route_prefixes: ["1"])
├── SIP Trunk "Enterprise Dedicated" ← assigned to Account B
│
├── Account "Business A" → uses shared trunks
├── Account "Business B" → uses dedicated trunk (always)
└── Account "Business C" → uses shared trunks
```

**Pattern 3: Multiple Trunks with Route Prefixes**

Use `outbound_route_prefixes` to route different destinations through different trunks:

```
SIP Trunk "Local US"     route_prefixes: ["1415", "1650"]  ← SF Bay Area
SIP Trunk "National US"  route_prefixes: ["1"]             ← Rest of US
SIP Trunk "International" route_prefixes: []               ← Everything else
```

The system selects trunks by longest prefix match.

---

## Authentication Modes

SIP trunks support three authentication modes:

| Mode | Description | Inbound Identification | Use Case |
|---|---|---|---|
| `ip_address` | Remote PBX identified by source IP. No credentials. | Source IP matching | Dedicated PBX with static IP |
| `client_credentials` | Somleng generates username/password. Remote PBX registers TO Somleng. | SIP username lookup | Cloud PBX, softphones |
| `outbound_registration` | You provide credentials. Somleng registers TO your PBX. | Gateway identification (automatic) | Connecting to an existing PBX/ITSP |

### How Each Mode Identifies Inbound Calls

**`ip_address`**: The system matches the source IP of incoming SIP INVITEs against the trunk's `inbound_source_ips` list.

**`client_credentials`**: The remote PBX includes its username in SIP headers. The system looks up the trunk by username.

**`outbound_registration`**: When Somleng registers with your PBX, it creates a FreeSWITCH gateway. Inbound calls arriving through that gateway are automatically tagged with the trunk ID — no IP configuration needed. This is the most reliable method for cloud PBX setups where the PBX IP may change.

---

## Inbound Call Routing

### How an inbound call reaches a business's webhook

```
External Call → FreeSWITCH → Identify SIP Trunk → Find Phone Number → Fetch TwiML → Execute
```

**Step-by-step:**

1. **SIP INVITE arrives** at FreeSWITCH on the `nat_gateway` profile.

2. **Identify the SIP trunk** using one of three methods (in priority order):
   - `gateway_id` — call arrived through a registered gateway (`outbound_registration`)
   - `client_identifier` — SIP username from headers (`client_credentials`)
   - `source_ip` — match against `inbound_source_ips` (`ip_address`)

3. **Normalize the destination number** using the trunk's `inbound_country` setting (e.g. strip national prefix, add country code).

4. **Find the Incoming Phone Number** — look up the normalized number in the trunk's carrier's active phone numbers.

5. **Route the call** based on the phone number's configuration:
   - If `voice_url` is set: HTTP request to the webhook, execute returned TwiML
   - If `sip_domain` is set: generate `<Dial><Sip>sip://number@domain</Sip></Dial>` automatically

6. **Create a PhoneCall record** tagged with the account, carrier, trunk, and incoming phone number.

### Example: Inbound Call Webhook

When a call arrives at a number configured with `voice_url: "https://app.example.com/voice"`, the system sends:

```
POST https://app.example.com/voice
Content-Type: application/x-www-form-urlencoded

CallSid=call-abc-123
From=+19175551234
To=+14155551234
Direction=inbound
AccountSid=account-xyz
CallStatus=ringing
ApiVersion=2010-04-01
```

The webhook returns TwiML to control the call:

```xml
<Response>
  <Say>Welcome to Acme Corp.</Say>
  <Gather numDigits="1" action="/menu">
    <Say>Press 1 for sales, 2 for support.</Say>
  </Gather>
</Response>
```

### Setting Up Inbound Numbers for a Business

1. **Create an Account** for the business (via carrier dashboard or API).
2. **Assign a Phone Number** to the account — this creates an Incoming Phone Number.
3. **Configure the Incoming Phone Number** with:
   - `voice_url`: The business's webhook endpoint (returns TwiML)
   - Or `sip_domain`: Route calls to the business's own SIP infrastructure
4. **Ensure a SIP trunk** is configured with the correct authentication mode so inbound calls can be identified.

---

## Outbound Call Routing

### How outbound calls select a SIP trunk

```
API Call → Select SIP Trunk → Build Dial String → FreeSWITCH → External
```

**Trunk selection priority:**

1. **Account's dedicated trunk** — if `account.sip_trunk_id` is set and the trunk supports outbound, use it.
2. **Carrier's shared trunks by route prefix** — match the destination number against `outbound_route_prefixes` (longest match wins).
3. **Default trunk** — a trunk with no `outbound_route_prefixes` acts as a catch-all.

### Outbound Dial String Construction

The dial string is built from the trunk's configuration:

| Setting | Effect |
|---|---|
| `outbound_host` | SIP server to send the INVITE to |
| `outbound_dial_string_prefix` | Prepended to the number (e.g. `9` for outside line) |
| `outbound_plus_prefix` | Adds `+` before the number |
| `outbound_national_dialing` | Strips country code, uses national format |

**For `outbound_registration` trunks**, calls are routed through the FreeSWITCH gateway:
```
sofia/gateway/{trunk_id}/{destination_number}
```

**For `ip_address` / `client_credentials` trunks**, calls are routed directly:
```
sofia/nat_gateway/sip:{destination_number}@{outbound_host}
```

### Making Outbound Calls (Twilio-Compatible API)

```bash
curl -X POST "https://api.somleng.dev/2010-04-01/Accounts/{account_sid}/Calls" \
  -u "{account_sid}:{auth_token}" \
  -d "To=+14155551234" \
  -d "From=+19175559876" \
  -d "Url=https://app.example.com/outbound-voice"
```

- `From` must be an Incoming Phone Number owned by the account.
- `To` is the destination number in E.164 format.
- `Url` returns TwiML to execute when the call connects.

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
        "outbound_proxy": null,
        "auth_user": null,
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
      "outbound_host": "pbx.example.com:5060",
      "outbound_proxy": null,
      "auth_user": null
    }
  }
}
```

When using `outbound_registration`, Somleng will create a FreeSWITCH gateway that actively sends SIP REGISTER to the specified `outbound_host`. Once registered, both outbound and inbound calls can be routed through this trunk.

**Inbound calls via registration:**

For `outbound_registration` trunks, inbound calls from the remote PBX are automatically identified by the gateway they arrive on — no `inbound_source_ips` configuration is needed. The gateway tags each inbound call with the trunk ID, so the system matches it directly without relying on source IP matching. The caller ID (From header) from the PBX is passed through as-is, even if it's not in E.164 format (e.g., PBX extensions like `6703` are accepted).

**Optional registration fields:**

- `outbound_proxy`: A proxy used to reach your SIP server for registration. Most often unset, but may be used if you need to register as `alice@trunk.com` using `proxy.trunk.com` as the network hop. When set, SIP REGISTER and INVITE messages are sent via this proxy instead of directly to `outbound_host`.
- `auth_user`: The authentication username, if different from the SIP `username`. Most often unset. Use this when the SIP identity (From header) differs from the credentials used in digest authentication.

#### Attributes

| Attribute | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Name of the SIP trunk. |
| `authentication_mode` | string | Yes | Authentication method: `ip_address`, `client_credentials`, or `outbound_registration`. |
| `region` | string | Yes | Region alias where the trunk is deployed (e.g. `hydrogen`). Must match a valid `SomlengRegion::Region` alias. |
| `max_channels` | integer | No | Maximum number of concurrent channels. Must be greater than 0. |
| `inbound_country` | string | No | ISO 3166-1 alpha-2 country code for inbound calls (e.g. `US`, `KH`). Used to normalize incoming numbers (strip national prefix, add country code). |
| `inbound_source_ips` | array of strings | No | List of allowed source IPv4 addresses for inbound traffic. Required for `ip_address` mode. Not needed for `outbound_registration`. |
| `default_sender` | string | No | Default sender/caller ID. |
| `username` | string | Conditional | SIP username. Required for `outbound_registration`. Auto-generated for `client_credentials`. |
| `password` | string | Conditional | SIP password. Required for `outbound_registration`. Auto-generated for `client_credentials`. |
| `outbound_host` | string | Conditional | The SIP server to register with. Required for `outbound_registration`. Format: `host` or `host:port`. Used as the SIP realm (domain identity in From header). |
| `outbound_proxy` | string or null | No | A proxy used to reach your SIP server for registration. When set, SIP messages are routed via this proxy instead of directly to `outbound_host`. Format: `host` or `host:port`. Max 100 chars. |
| `auth_user` | string or null | No | The authentication username for digest auth, if different from `username`. Max 60 chars. |
| `outbound_dial_string_prefix` | string | No | Prefix prepended to the dial string for outbound calls. |
| `outbound_national_dialing` | boolean | No | Whether to use national dialing format for outbound calls. |
| `outbound_plus_prefix` | boolean | No | Whether to prepend `+` to outbound dial strings. |
| `outbound_route_prefixes` | array of strings | No | List of number prefixes used for outbound routing. Longest match wins. Empty list = default/catch-all trunk. |

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

When updating an `outbound_registration` trunk's `username`, `password`, `outbound_host`, `outbound_proxy`, or `auth_user`, the FreeSWITCH gateway is automatically recreated with the new configuration.

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
