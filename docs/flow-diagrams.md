# Chorus SIP Stack - Flow Diagrams

Detailed SIP signaling, HTTP, and WebSocket flows between:
- **AI Agent** (connected via WebSocket / TwiML)
- **Chorus SIP Stack** (API + FreeSWITCH + Switch)
- **Client Contact Center** (PBX / SIP Endpoints)

---

## 1. IP Authentication & SIP Registration

### 1a. IP Address Authentication (No Registration Required)

```
┌──────────────────┐                        ┌─────────────────────────┐
│  Client PBX      │                        │  Chorus SIP Stack (FreeSWITCH)  │
│  (Static IP:     │                        │                         │
│   203.0.113.50)  │                        │                         │
└────────┬─────────┘                        └────────────┬────────────┘
         │                                               │
         │  SIP INVITE sip:+14155551234@chorus:5060    │
         │  Via: SIP/2.0/UDP 203.0.113.50:5060           │
         │  From: <sip:+19175551234@203.0.113.50>        │
         │  To: <sip:+14155551234@chorus:5060>         │
         │  Contact: <sip:+19175551234@203.0.113.50>     │
         │  Content-Type: application/sdp                 │
         │──────────────────────────────────────────────>│
         │                                               │
         │                          ┌────────────────────┤
         │                          │ IP Auth Check:     │
         │                          │ source_ip =        │
         │                          │  203.0.113.50      │
         │                          │                    │
         │                          │ SIPTrunkResolver   │
         │                          │ .find_sip_trunk_by(│
         │                          │   source_ip,       │
         │                          │   destination)     │
         │                          │                    │
         │                          │ Match against      │
         │                          │ inbound_source_ips │
         │                          │ on SIP Trunk       │
         │                          └────────────────────┤
         │                                               │
         │  SIP 100 Trying                               │
         │<──────────────────────────────────────────────│
         │                                               │
         │  SIP 200 OK (if authenticated)                │
         │<──────────────────────────────────────────────│
         │                                               │
         │  SIP ACK                                      │
         │──────────────────────────────────────────────>│
         │                                               │
```

### 1b. Client Credentials Authentication (Client Registers TO Chorus SIP Stack)

```
┌──────────────────┐                        ┌─────────────────────────┐
│  Client PBX      │                        │  Chorus SIP Stack (FreeSWITCH)  │
│  (Softphone/     │                        │  nat_gateway profile    │
│   Cloud PBX)     │                        │  Port 5060              │
└────────┬─────────┘                        └────────────┬────────────┘
         │                                               │
         │  SIP REGISTER sip:chorus:5060               │
         │  From: <sip:client_user@chorus>             │
         │  To: <sip:client_user@chorus>               │
         │  Contact: <sip:client_user@client_ip:5060>    │
         │  Expires: 3600                                │
         │──────────────────────────────────────────────>│
         │                                               │
         │  SIP 401 Unauthorized                         │
         │  WWW-Authenticate: Digest realm="chorus",   │
         │    nonce="abc123", algorithm=MD5               │
         │<──────────────────────────────────────────────│
         │                                               │
         │  SIP REGISTER sip:chorus:5060               │
         │  Authorization: Digest username="client_user", │
         │    realm="chorus", nonce="abc123",           │
         │    uri="sip:chorus:5060",                    │
         │    response="<md5_hash>"                       │
         │  X-Chorus-Client-Identifier: client_user     │
         │  Expires: 3600                                │
         │──────────────────────────────────────────────>│
         │                                               │
         │                          ┌────────────────────┤
         │                          │ Verify credentials │
         │                          │ against SIP Trunk  │
         │                          │ username/password   │
         │                          └────────────────────┤
         │                                               │
         │  SIP 200 OK                                   │
         │  Contact: <sip:client_user@client_ip:5060>    │
         │  Expires: 3600                                │
         │<──────────────────────────────────────────────│
         │                                               │
         ▼          (Re-REGISTER every ~1800s)           ▼
```

### 1c. Outbound Registration (Chorus SIP Stack Registers WITH Remote PBX)

```
┌─────────────────┐    ┌────────────────┐    ┌───────────────────────┐    ┌──────────────┐
│  Carrier Admin   │    │  Chorus API   │    │  Switch (Gateway Mgr) │    │  FreeSWITCH  │
│  (HTTP Client)   │    │  Port 3000     │    │  Port 8080            │    │  ESL 8021    │
└────────┬────────┘    └───────┬────────┘    └──────────┬────────────┘    └──────┬───────┘
         │                     │                        │                        │
         │ POST /carrier/v1/sip_trunks                  │                        │
         │ Authorization: Bearer {token}                │                        │
         │ {                                            │                        │
         │   "authentication_mode":                     │                        │
         │     "outbound_registration",                 │                        │
         │   "username": "chorus_user",                │                        │
         │   "password": "secret123",                   │                        │
         │   "outbound_host": "pbx.client.com:5060"     │                        │
         │ }                                            │                        │
         │────────────────────>│                        │                        │
         │                     │                        │                        │
         │                     │ CreateSIPTrunk workflow │                        │
         │                     │ Parse host/port/realm   │                        │
         │                     │                        │                        │
         │                     │ POST /gateways          │                        │
         │                     │ {                       │                        │
         │                     │   "name": "{trunk_id}", │                        │
         │                     │   "username":            │                        │
         │                     │     "chorus_user",      │                        │
         │                     │   "password":"secret123",│                        │
         │                     │   "host":                │                        │
         │                     │     "pbx.client.com",    │                        │
         │                     │   "port": "5060"         │                        │
         │                     │ }                       │                        │
         │                     │───────────────────────>│                        │
         │                     │                        │                        │
         │                     │                        │ Write gateway XML:     │
         │                     │                        │ /sip_gateways/         │
         │                     │                        │   {trunk_id}.xml       │
         │                     │                        │                        │
         │                     │                        │ TCP ESL Connection     │
         │                     │                        │───────────────────────>│
         │                     │                        │                        │
         │                     │                        │ auth {password}\n\n    │
         │                     │                        │───────────────────────>│
         │                     │                        │                        │
         │                     │                        │ +OK accepted           │
         │                     │                        │<───────────────────────│
         │                     │                        │                        │
         │                     │                        │ api sofia profile      │
         │                     │                        │   nat_gateway rescan   │
         │                     │                        │───────────────────────>│
         │                     │                        │                        │
         │                     │  201 Created            │                        │
         │                     │<───────────────────────│                        │
         │                     │                        │                        │
         │  201 Created        │                        │                        │
         │<────────────────────│                        │                        │
         │                     │                        │                        │


┌──────────────┐                                              ┌──────────────────┐
│  FreeSWITCH  │                                              │  Remote PBX      │
│  nat_gateway │                                              │  pbx.client.com  │
└──────┬───────┘                                              └────────┬─────────┘
       │                                                               │
       │  SIP REGISTER sip:pbx.client.com SIP/2.0                     │
       │  Via: SIP/2.0/UDP chorus_ip:5060                            │
       │  From: <sip:chorus_user@pbx.client.com>;tag=fs_xxxxx        │
       │  To: <sip:chorus_user@pbx.client.com>                       │
       │  Contact: <sip:chorus_user@chorus_ip:5060>                │
       │  Expires: 120                                                 │
       │  CSeq: 1 REGISTER                                            │
       │──────────────────────────────────────────────────────────────>│
       │                                                               │
       │  SIP 401 Unauthorized                                         │
       │  WWW-Authenticate: Digest realm="pbx.client.com",             │
       │    nonce="xyz789", algorithm=MD5                               │
       │<──────────────────────────────────────────────────────────────│
       │                                                               │
       │  SIP REGISTER sip:pbx.client.com SIP/2.0                     │
       │  Authorization: Digest username="chorus_user",               │
       │    realm="pbx.client.com", nonce="xyz789",                    │
       │    response="<md5_digest>"                                    │
       │  Expires: 120                                                 │
       │──────────────────────────────────────────────────────────────>│
       │                                                               │
       │  SIP 200 OK                                                   │
       │  Expires: 120                                                 │
       │<──────────────────────────────────────────────────────────────│
       │                                                               │
       │         (Re-REGISTER every ~60s, OPTIONS ping every 25s)      │
       │                                                               │
       │  SIP OPTIONS sip:pbx.client.com SIP/2.0                      │
       │──────────────────────────────────────────────────────────────>│
       │  SIP 200 OK                                                   │
       │<──────────────────────────────────────────────────────────────│
       │                                                               │
```

---

## 2. Inbound Call Processing (Client Contact Center -> AI Agent)

```
┌──────────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────────┐  ┌────────────┐
│ Client       │  │ FreeSWITCH   │  │ Chorus│  │ Chorus API  │  │ AI Agent   │
│ Contact Ctr  │  │ (nat_gateway)│  │ Switch    │  │ (Port 3000)  │  │ (WebSocket)│
│ (PBX)       │  │ (Port 5060)  │  │ (Rayo)    │  │              │  │            │
└──────┬───────┘  └──────┬───────┘  └─────┬─────┘  └──────┬───────┘  └─────┬──────┘
       │                 │                │               │                │
       │ ============== PHASE 1: SIP SIGNALING ========== │                │
       │                 │                │               │                │
       │ SIP INVITE      │                │               │                │
       │ sip:+1415555    │                │               │                │
       │ 1234@chorus   │                │               │                │
       │ :5060           │                │               │                │
       │ From: <sip:+1917│                │               │                │
       │ 5551234@client> │                │               │                │
       │ To: <sip:+14155 │                │               │                │
       │ 551234@chorus>│                │               │                │
       │ Content-Type:   │                │               │                │
       │  application/sdp│                │               │                │
       │────────────────>│                │               │                │
       │                 │                │               │                │
       │ SIP 100 Trying  │                │               │                │
       │<────────────────│                │               │                │
       │                 │                │               │                │
       │                 │ ============== PHASE 2: CALL ROUTING ========== │
       │                 │                │               │                │
       │                 │ Rayo OFFER     │               │                │
       │                 │ (call arrives  │               │                │
       │                 │  via dialplan  │               │                │
       │                 │  -> rayo app)  │               │                │
       │                 │───────────────>│               │                │
       │                 │                │               │                │
       │                 │                │ ── Identify SIP Trunk ──       │
       │                 │                │ 1. Check gateway_id var        │
       │                 │                │ 2. Check X-Chorus-            │
       │                 │                │    Client-Identifier           │
       │                 │                │ 3. Check source IP vs          │
       │                 │                │    inbound_source_ips          │
       │                 │                │               │                │
       │                 │                │ HTTP POST     │                │
       │                 │                │ /services/    │                │
       │                 │                │ inbound_      │                │
       │                 │                │ phone_calls   │                │
       │                 │                │ {             │                │
       │                 │                │  "to":"+14155 │                │
       │                 │                │   551234",    │                │
       │                 │                │  "from":"+1917│                │
       │                 │                │   5551234",   │                │
       │                 │                │  "source_ip": │                │
       │                 │                │   "203.0.113.5│                │
       │                 │                │   0",         │                │
       │                 │                │  "external_id"│                │
       │                 │                │   :"{uuid}"   │                │
       │                 │                │ }             │                │
       │                 │                │──────────────>│                │
       │                 │                │               │                │
       │                 │                │               │ ── Lookup ──   │
       │                 │                │               │ 1. Find SIP    │
       │                 │                │               │    Trunk by IP │
       │                 │                │               │ 2. Normalize # │
       │                 │                │               │    (country)   │
       │                 │                │               │ 3. Find        │
       │                 │                │               │    Incoming    │
       │                 │                │               │    Phone #     │
       │                 │                │               │ 4. Get         │
       │                 │                │               │    voice_url   │
       │                 │                │               │                │
       │                 │                │ 200 OK        │                │
       │                 │                │ {call_sid,    │                │
       │                 │                │  voice_url,   │                │
       │                 │                │  account_sid} │                │
       │                 │                │<──────────────│                │
       │                 │                │               │                │
       │                 │ ============== PHASE 3: TWIML FETCH =========  │
       │                 │                │               │                │
       │                 │                │ HTTP POST {voice_url}          │
       │                 │                │ (e.g. https://app.client.com/  │
       │                 │                │  incoming-call)                │
       │                 │                │ Params:                        │
       │                 │                │  CallSid={call_sid}            │
       │                 │                │  From=+19175551234             │
       │                 │                │  To=+14155551234               │
       │                 │                │  Direction=inbound             │
       │                 │                │  CallStatus=ringing            │
       │                 │                │─────────────────────────────>  │
       │                 │                │          (to client webhook)   │
       │                 │                │                                │
       │                 │                │ TwiML Response:                │
       │                 │                │ <Response>                     │
       │                 │                │  <Connect>                     │
       │                 │                │   <Stream url="wss://         │
       │                 │                │    ai.example.com/ws"/>        │
       │                 │                │  </Connect>                    │
       │                 │                │ </Response>                    │
       │                 │                │<─────────────────────────────  │
       │                 │                │                                │
       │ SIP 200 OK      │                │               │                │
       │ (SDP answer)    │                │               │                │
       │<────────────────│                │               │                │
       │                 │                │               │                │
       │ SIP ACK         │                │               │                │
       │────────────────>│                │               │                │
       │                 │                │               │                │
       │                 │ ============== PHASE 4: AI CONNECTION ========  │
       │                 │                │               │                │
       │                 │                │ Rayo Command:  │                │
       │                 │                │ MediaStream::  │                │
       │                 │                │ Start          │                │
       │                 │                │ {uuid, url,    │                │
       │                 │                │  metadata}     │                │
       │                 │                │───────────────>│                │
       │                 │                │               │                │
       │                 │  mod_audio      │               │                │
       │                 │  _stream opens  │               │                │
       │                 │  WebSocket      │               │                │
       │                 │                │               │                │
       │                 │ ─────────────── WebSocket Handshake ──────────>│
       │                 │ GET /ws HTTP/1.1                                │
       │                 │ Upgrade: websocket                              │
       │                 │ Connection: Upgrade                             │
       │                 │ Sec-WebSocket-Version: 13                       │
       │                 │                │               │                │
       │                 │ <───────── 101 Switching Protocols ───────────│
       │                 │                │               │                │
       │                 │ ─── WS: {"event":"connected", ───────────────>│
       │                 │       "protocol":"Call",                        │
       │                 │       "version":"1.0.0"}                        │
       │                 │                │               │                │
       │                 │ ─── WS: {"event":"start", ───────────────────>│
       │                 │       "streamSid":"{stream_sid}",              │
       │                 │       "start":{                                 │
       │                 │         "callSid":"{call_sid}",                │
       │                 │         "accountSid":"{acct_sid}",             │
       │                 │         "customParameters":{...}               │
       │                 │       }}                                        │
       │                 │                │               │                │
       │                 │                │ HTTP POST /services/           │
       │                 │                │  media_stream_events           │
       │                 │                │ {"type":"connected"}           │
       │                 │                │──────────────>│                │
       │                 │                │               │                │
       │                 │ ============== PHASE 5: BIDIRECTIONAL MEDIA ==  │
       │                 │                │               │                │
       │  RTP Audio      │                │               │                │
       │  (caller voice) │                │               │                │
       │ ═══════════════>│                │               │                │
       │                 │ ── WS: {"event":"media", ────────────────────>│
       │                 │       "media":{                                 │
       │                 │         "payload":"<base64_audio>",            │
       │                 │         "timestamp":"...",                      │
       │                 │         "track":"inbound",                      │
       │                 │         "chunk":"1"                             │
       │                 │       }}                                        │
       │                 │                │               │       ┌───────┤
       │                 │                │               │       │ AI    │
       │                 │                │               │       │ STT   │
       │                 │                │               │       │ -> LLM│
       │                 │                │               │       │ -> TTS│
       │                 │                │               │       └───────┤
       │                 │ <── WS: {"event":"media", ──────────────────<│
       │                 │       "media":{                                 │
       │                 │         "payload":"<base64_audio>",            │
       │                 │         "track":"outbound"                      │
       │                 │       }}                                        │
       │                 │                │               │                │
       │  RTP Audio      │                │               │                │
       │  (AI response)  │                │               │                │
       │<═══════════════│                │               │                │
       │                 │                │               │                │
       │     ... continuous bidirectional audio ...       │                │
       │                 │                │               │                │
```

---

## 3. Outbound Call Initiation (AI/App -> Client Contact Center)

```
┌────────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────────┐  ┌──────────────┐
│ App/AI     │  │ Chorus API  │  │ Chorus│  │ FreeSWITCH   │  │ Client       │
│ (Triggers  │  │ (Port 3000)  │  │ Switch    │  │ (nat_gateway)│  │ Contact Ctr  │
│  call)     │  │              │  │ (Rayo)    │  │ (Port 5060)  │  │ (PBX)       │
└─────┬──────┘  └──────┬───────┘  └─────┬─────┘  └──────┬───────┘  └──────┬───────┘
      │                │               │               │                │
      │ ============== PHASE 1: API CALL CREATION ====== │                │
      │                │               │               │                │
      │ POST /2010-04-01/Accounts/     │               │                │
      │  {acct_sid}/Calls              │               │                │
      │ Authorization: Basic           │               │                │
      │  {acct_sid}:{auth_token}       │               │                │
      │ Body:                          │               │                │
      │  To=+14155551234               │               │                │
      │  From=+19175559876             │               │                │
      │  Url=https://app.example       │               │                │
      │    .com/outbound-handler       │               │                │
      │───────────────>│               │               │                │
      │                │               │               │                │
      │                │ ── Select SIP Trunk ──         │                │
      │                │ 1. Account dedicated trunk     │                │
      │                │ 2. Route prefix match          │                │
      │                │    (longest prefix wins)       │                │
      │                │ 3. Default trunk               │                │
      │                │               │               │                │
      │                │ ── Build Routing Params ──     │                │
      │                │ destination: +14155551234      │                │
      │                │ dial_string_prefix: ""         │                │
      │                │ host: pbx.client.com           │                │
      │                │ auth_mode: outbound_reg        │                │
      │                │ gateway: {trunk_id}            │                │
      │                │               │               │                │
      │  202 Accepted  │               │               │                │
      │  {call_sid}    │               │               │                │
      │<───────────────│               │               │                │
      │                │               │               │                │
      │                │ ============== PHASE 2: ORIGINATE CALL ======== │
      │                │               │               │                │
      │                │ Originate     │               │                │
      │                │ command to    │               │                │
      │                │ Switch        │               │                │
      │                │──────────────>│               │                │
      │                │               │               │                │
      │                │               │ ── Build Dial String ──        │
      │                │               │                                │
      │                │               │ For outbound_registration:     │
      │                │               │ "{sip_invite_req_uri=          │
      │                │               │  sip:14155551234@              │
      │                │               │  pbx.client.com,               │
      │                │               │  sip_invite_domain=            │
      │                │               │  pbx.client.com}               │
      │                │               │  sofia/gateway/                │
      │                │               │  {trunk_id}/                   │
      │                │               │  14155551234"                  │
      │                │               │                                │
      │                │               │ For ip_address:                │
      │                │               │ "{sofia_suppress_url_encoding  │
      │                │               │  =true,sip_invite_domain=     │
      │                │               │  pbx.client.com}               │
      │                │               │  sofia/nat_gateway/            │
      │                │               │  sip:14155551234@              │
      │                │               │  pbx.client.com:5060"          │
      │                │               │               │                │
      │                │               │ Adhearsion     │                │
      │                │               │ OutboundCall   │                │
      │                │               │ .originate()   │                │
      │                │               │──────────────>│                │
      │                │               │               │                │
      │                │               │               │ SIP INVITE     │
      │                │               │               │ sip:14155551234│
      │                │               │               │ @pbx.client.com│
      │                │               │               │ :5060          │
      │                │               │               │ From: <sip:    │
      │                │               │               │ +19175559876@  │
      │                │               │               │ chorus>      │
      │                │               │               │ To: <sip:      │
      │                │               │               │ +14155551234@  │
      │                │               │               │ pbx.client.com>│
      │                │               │               │ X-Chorus-Call │
      │                │               │               │ -Sid:{call_sid}│
      │                │               │               │ Content-Type:  │
      │                │               │               │ application/sdp│
      │                │               │               │───────────────>│
      │                │               │               │                │
      │                │               │               │ SIP 100 Trying │
      │                │               │               │<───────────────│
      │                │               │               │                │
      │                │               │               │ SIP 180 Ringing│
      │                │               │               │<───────────────│
      │                │               │               │                │
      │                │               │ Event: Ringing │                │
      │                │               │<──────────────│                │
      │                │               │               │                │
      │                │               │ HTTP POST     │                │
      │                │               │ /services/    │                │
      │                │               │ phone_call_   │                │
      │                │               │ events        │                │
      │                │               │ {"type":      │                │
      │                │               │  "ringing"}   │                │
      │                │               │──────────────>│                │
      │                │               │               │                │
      │                │               │               │ SIP 200 OK     │
      │                │               │               │ (SDP answer)   │
      │                │               │               │<───────────────│
      │                │               │               │                │
      │                │               │               │ SIP ACK        │
      │                │               │               │───────────────>│
      │                │               │               │                │
      │                │               │ Event:Answered │                │
      │                │               │<──────────────│                │
      │                │               │               │                │
      │                │ ============== PHASE 3: TWIML EXECUTION ======  │
      │                │               │               │                │
      │                │               │ HTTP POST     │                │
      │                │               │ https://app.  │                │
      │                │               │ example.com/  │                │
      │                │               │ outbound-     │                │
      │                │               │ handler       │                │
      │                │               │ Params:       │                │
      │                │               │  CallSid,From,│                │
      │                │               │  To,Direction=│                │
      │                │               │  outbound,    │                │
      │                │               │  CallStatus=  │                │
      │                │               │  in-progress  │                │
      │                │               │──────────────────────────────> │
      │                │               │              (to app webhook)  │
      │                │               │                                │
      │                │               │ TwiML Response:                │
      │                │               │ <Response>                     │
      │                │               │  <Connect>                     │
      │                │               │   <Stream url="wss://          │
      │                │               │    ai.example.com/ws"/>        │
      │                │               │  </Connect>                    │
      │                │               │ </Response>                    │
      │                │               │<──────────────────────────────│
      │                │               │               │                │
      │                │               │   ... WebSocket + Media flow   │
      │                │               │   (same as Inbound Phase 4-5)  │
      │                │               │               │                │
```

---

## 4. Call Handback (AI Completes -> PBX Retains Control)

When the AI interaction completes, Chorus ends its call leg. The client PBX
retains full control of the original caller and handles all subsequent routing
(transfer to agent, queue, IVR, etc.) using its own dial plan logic.

Chorus never performs SIP REFER or initiates transfers — the call must remain
under the client PBX's control at all times.

```
┌──────────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────────┐
│ Caller       │  │ Client PBX   │  │ Chorus   │  │ AI Agent     │
│ (Phone/SIP)  │  │              │  │ FreeSWITCH│  │ (WebSocket)  │
└──────┬───────┘  └──────┬───────┘  └─────┬─────┘  └──────┬───────┘
       │                 │               │               │
       │  (Active call)  │  (Active leg)  │  (WS stream)  │
       │<═══════════════>│<═════════════>│<═════════════>│
       │                 │               │               │
       │ ============== AI INTERACTION COMPLETES ══════  │
       │                 │               │               │
       │                 │               │  WS: stop     │
       │                 │               │  (stream ends) │
       │                 │               │<──────────────│
       │                 │               │               │
       │                 │               │ WS closed     │
       │                 │               │               │
       │                 │  SIP BYE      │               │
       │                 │  (Chorus      │               │
       │                 │   releases    │               │
       │                 │   its leg)    │               │
       │                 │<──────────────│               │
       │                 │               │               │
       │                 │  SIP 200 OK   │               │
       │                 │──────────────>│               │
       │                 │               │               │
       │ ============== PBX TAKES OVER ════════════════  │
       │                 │                                │
       │                 │ PBX dial plan continues:       │
       │                 │  - Route to agent queue        │
       │                 │  - Transfer to extension       │
       │                 │  - Play IVR menu               │
       │                 │  - Any PBX-native logic        │
       │                 │                                │
       │  (Caller never  │                                │
       │   left the PBX) │                                │
       │<═══════════════>│                                │
       │                 │                                │
```

---

## 5. Complete End-to-End: Inbound Call -> AI -> Hangup

```
┌──────────────┐  ┌──────────────┐  ┌───────────┐  ┌────────────┐
│ Caller       │  │ FreeSWITCH   │  │ Switch +  │  │ AI Agent   │
│ (Phone/SIP)  │  │              │  │ Chorus│  │ (WS/TwiML) │
└──────┬───────┘  └──────┬───────┘  └─────┬─────┘  └─────┬──────┘
       │                 │               │              │
  ════════════════════════════════════════════════════════
  STEP 1: CALLER DIALS IN
  ════════════════════════════════════════════════════════
       │                 │               │              │
       │ INVITE ────────>│               │              │
       │ 100 Trying <────│               │              │
       │                 │ Rayo OFFER ──>│              │
       │                 │               │              │
  ════════════════════════════════════════════════════════
  STEP 2: AUTHENTICATE & ROUTE
  ════════════════════════════════════════════════════════
       │                 │               │              │
       │                 │               │─ IP auth ──>│
       │                 │               │  (Chorus │
       │                 │               │   API)       │
       │                 │               │<── voice_url │
       │                 │               │   + call_sid │
       │                 │               │              │
  ════════════════════════════════════════════════════════
  STEP 3: FETCH TWIML -> CONNECT TO AI
  ════════════════════════════════════════════════════════
       │                 │               │              │
       │                 │               │─ POST ─────>│
       │                 │               │  {voice_url} │
       │                 │               │  (app webhook│
       │                 │               │   returns    │
       │                 │               │   <Connect>) │
       │                 │               │<─ TwiML ────│
       │                 │               │              │
       │ 200 OK <────────│               │              │
       │ ACK ───────────>│               │              │
       │                 │               │              │
  ════════════════════════════════════════════════════════
  STEP 4: AI MEDIA STREAMING (Bidirectional)
  ════════════════════════════════════════════════════════
       │                 │               │              │
       │                 │──── WS Connect ────────────>│
       │                 │<─── WS 101 Upgrade ────────│
       │                 │                              │
       │ RTP ═══════════>│── WS media(inbound) ──────>│
       │                 │                    STT ─────>│
       │                 │                    LLM ─────>│
       │                 │                    TTS ─────>│
       │ RTP <═══════════│<── WS media(outbound) ─────│
       │                 │                              │
       │    "Hi! How can I help you today?"             │
       │    "I need help with my account"               │
       │    "Sure, let me look into that..."            │
       │                 │                              │
  ════════════════════════════════════════════════════════
  STEP 5: CALL TERMINATION
  ════════════════════════════════════════════════════════
       │                 │               │              │
       │ BYE ───────────>│               │              │
       │ (caller hangs   │               │              │
       │  up)            │               │              │
       │ 200 OK <────────│               │              │
       │                 │               │              │
       │                 │               │ Event:       │
       │                 │               │ completed    │
       │                 │               │              │
       │                 │               │ HTTP POST    │
       │                 │               │ /services/   │
       │                 │               │ phone_call_  │
       │                 │               │ events       │
       │                 │               │ {"type":     │
       │                 │               │  "completed",│
       │                 │               │  "sip_term_  │
       │                 │               │  status":200,│
       │                 │               │  "duration": │
       │                 │               │  185}        │
       │                 │               │─────────────>│
       │                 │               │              │
       │                 │               │ Status callback
       │                 │               │ POST {status_
       │                 │               │  callback_url}
       │                 │               │ CallSid,
       │                 │               │ Duration,
       │                 │               │ CallStatus=
       │                 │               │  completed
       │                 │               │────────────>
       │                 │               │  (to app)
       │                 │               │              │
  ════════════════════════════════════════════════════════
```

---

## SIP Methods Reference

| Method       | Direction              | Purpose                                         |
|-------------|------------------------|--------------------------------------------------|
| `REGISTER`  | Chorus -> Remote PBX | Outbound registration (keep-alive every 120s)    |
| `REGISTER`  | Client -> Chorus     | Client credentials auth (client registers to us) |
| `INVITE`    | Client -> Chorus     | Inbound call initiation                          |
| `INVITE`    | Chorus -> Client     | Outbound call initiation                         |
| `100 Trying`| Both directions        | Call is being processed                          |
| `180 Ringing`| Both directions       | Destination is ringing                           |
| `200 OK`    | Both directions        | Success (call answered / registration accepted)  |
| `ACK`       | Follows INVITE         | Confirms receipt of 200 OK for INVITE            |
| `BYE`       | Either party           | Terminates an established call                   |
| `401 Unauthorized`| Challenge        | Digest authentication challenge                  |
| `OPTIONS`   | Chorus -> Remote PBX | Keep-alive ping (every 25s for gateways)         |
| `CANCEL`    | Either party           | Cancel pending INVITE before answer              |
| `486 Busy`  | Callee                 | Destination is busy                              |
| `408 Timeout`| Server                | Request timed out                                |
| `503 Unavail`| Server                | Service unavailable                              |

## HTTP API Endpoints (Internal)

| Endpoint                            | Method | Purpose                              |
|------------------------------------|--------|--------------------------------------|
| `/services/inbound_phone_calls`     | POST   | Register new inbound call            |
| `/services/phone_call_events`       | POST   | Report call lifecycle events         |
| `/services/media_stream_events`     | POST   | Report WebSocket stream events       |
| `/carrier/v1/sip_trunks`           | POST   | Create SIP trunk                     |
| `/gateways`                         | POST   | Create FreeSWITCH gateway            |
| `/gateways/{id}`                    | DELETE | Remove FreeSWITCH gateway            |
| `/2010-04-01/Accounts/{sid}/Calls`  | POST   | Create outbound call               |
| `{voice_url}`                       | POST   | Fetch TwiML from client webhook      |
| `{status_callback_url}`            | POST   | Notify client of call status changes |

## WebSocket Message Types (Media Stream Protocol)

| Event         | Direction          | Purpose                                  |
|---------------|-------------------|------------------------------------------|
| `connected`   | Server -> AI      | WebSocket connection established          |
| `start`       | Server -> AI      | Stream started, includes metadata         |
| `media`       | Bidirectional     | Audio frames (base64 mulaw/PCM)          |
| `stop`        | Either direction  | Stream is ending                          |
| `mark`        | Server -> AI      | Playback marker reached                   |
| `dtmf`        | Server -> AI      | DTMF digit detected                      |
| `clear`       | AI -> Server      | Clear audio playback queue                |
