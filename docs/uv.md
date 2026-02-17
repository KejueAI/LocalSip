2026-02-16 18:38:19.430 Loading scenario SipBase
2026-02-16 18:38:19.431 Loading scenario OutgoingSip
2026-02-16 18:38:19.431 Sent event to JS VoxEngine.customData with params [{"from": "sip:971525194521@zenith.bhycm.yeastarcloud.com:5060", "to": "sip:971547055538@zenith.bhycm.yeastarcloud.com:5060", "joinTimeoutMs": 30000, "joinUrl": "wss://voice.ultravox.ai/calls/d98d0e01-a800-4f48-bf27-9c277c3734da/server_web_socket", "endCallUrl": "https://api.ultravox.ai/api/internal/calls/d98d0e01-a800-4f48-bf27-9c277c3734da/end_sip", "endCallToken": "gAAAAABpk2QbffPXVrOCyJkwZlhG0lhMQLY5u-3ieddw8BnerQuXwU-OrZbowAfUj0ABvyiZSjvnFQGHYS0Ksv1q9CcLiD2HbvWjn6fHbe6rVGQ02uzG_maH_vwr3S5ZdRNOhIEvMXslYHDwlSFLByS4koOqKcNgLa9pnQN5_ImiF8LglkrOSMI=", "username": "6700", "password": "AwYW3t6ePN"} ;  ]
2026-02-16 18:38:19.431 Sent event to JS onPhoneEvent with params [{name = Application.Started ; accountId = 9997490 ; domainName = ultravox.uvx-jbrfiwvysx.voximplant.com ; dialplanName = ultravox-outgoing-sip ; dialplanId = 0 ; userId = -1 ; applicationId = 11024002 ; accessURL = http://109.61.92.230:12092/request/5014DA08C37601ED.1771267099.44321981_109.61.92.230/FD8FE1FAD3DB5EFA ; accessSecureURL = https://www-us-35-230.voximplant.com:12093/request/5014DA08C37601ED.1771267099.44321981_109.61.92.230/FD8FE1FAD3DB5EFA ; logURL = https://storage-gw-us-01.voximplant.com/voxdata-us-logs/2026/02/16/YWI5MmFjYTk4MjQ2MWEyOTlmODQ4YmRmYTRjODVjMjAvaHR0cDovL3d3dy11cy0zNS0yMzAudm94aW1wbGFudC5jb206ODA4MC9sb2dzLzIwMjYvMDIvMTYvMTgzODE5XzUwMTREQTA4QzM3NjAxRUQuMTc3MTI2NzA5OS40NDMyMTk4MV8xMDkuNjEuOTIuMjMwLmxvZw--?sessionid=4278792344 ; sessionId = 4278792344 ; nluAddresses = [https://ai-eu-1.voximplant.com/ ;  ] ; config = {acceptReInviteByDefault = true ; } ; } ;  ]
2026-02-16 18:38:19.488 Module loaded: ultravox
2026-02-16 18:38:19.488 Executing JS command: SetCustomData with params [{data = {"from": "sip:971525194521@zenith.bhycm.yeastarcloud.com:5060", "to": "sip:971547055538@zenith.bhycm.yeastarcloud.com:5060", "joinTimeoutMs": 30000, "joinUrl": "wss://voice.ultravox.ai/calls/d98d0e01-a800-4f48-bf27-9c277c3734da/server_web_socket", "endCallUrl": "https://api.ultravox.ai/api/internal/calls/d98d0e01-a800-4f48-bf27-9c277c3734da/end_sip", "endCallToken": "gAAAAABpk2QbffPXVrOCyJkwZlhG0lhMQLY5u-3ieddw8BnerQuXwU-OrZbowAfUj0ABvyiZSjvnFQGHYS0Ksv1q9CcLiD2HbvWjn6fHbe6rVGQ02uzG_maH_vwr3S5ZdRNOhIEvMXslYHDwlSFLByS4koOqKcNgLa9pnQN5_ImiF8LglkrOSMI=", "username": "6700", "password": "AwYW3t6ePN"} ; } ;  ]
2026-02-16 18:38:19.488 VoxEngine version: 7.23.0
2026-02-16 18:38:19.488 Executing JS command: CallSIP with params [{id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; } ;  {authUser = 6700 ; callerid = sip:971525194521@zenith.bhycm.yeastarcloud.com:5060 ; headers = NULL ; password = ****** ; to = sip:971547055538@zenith.bhycm.yeastarcloud.com:5060 ; } ;  ]
2026-02-16 18:38:19.488 Executing JS command: EnableMediaStatistics with params [{id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; } ;  ]
2026-02-16 18:38:19.488 WARNING! The valid 'supportedDtmfTypes' parameter value is not provided, the default 'ALL' value will be used.
2026-02-16 18:38:19.488 Executing JS command: HandleTones with params [{handle = true ; id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; } ;  ]
2026-02-16 18:38:23.870 CallId=UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0: Enable media statistics for UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 : https://storage-gw-us-01.voximplant.com/voxdata-us-logs/2026/02/16/YWU2ZTllYmFkNmQyMTUxNjNlMGYwZDRkNTZhNzg4NzgvaHR0cDovL3d3dy11cy0zNS0yMzAudm94aW1wbGFudC5jb206ODA4MC9sb2dzLzIwMjYvMDIvMTYvNTAxNERBMDhDMzc2MDFFRC4xNzcxMjY3MDk5LjQ0MzIxOTgxXzEwOS42MS45Mi4yMzBfVWh4ZERHNjRUM0d2a2JZUm0tQkl1MEFiakJoUzAwX3BsYURiYVBoNHZjMC5jc3Y-?sessionid=4278792344

-----BEGIN SIP TRACE UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 
2026-02-16 18:38:19.579  Sent:
INVITE sip:971547055538@zenith.bhycm.yeastarcloud.com:5060 SIP/2.0
v: SIP/2.0/UDP 109.61.92.230:5090;rport;branch=z9hG4bKPjf2af7869-bd50-4648-8d8d-47605f589a96
Max-Forwards: 70
f: sip:971525194521@zenith.bhycm.yeastarcloud.com;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: sip:971547055538@zenith.bhycm.yeastarcloud.com
m: <sip:971525194521@109.61.92.230:5090>
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
CSeq: 20762 INVITE
Route: <sip:3.147.160.14:5060;lr>
Allow: INFO, INVITE, ACK, BYE, CANCEL, UPDATE, PRACK, SUBSCRIBE, NOTIFY, REFER
k: 100rel, replaces
VI-Identity: voxkeys/20251125 eyJhbGciIDogIkhTMjU2IiAsICJ0eXAiIDogIkpXVCJ9.eyJleHAiIDogMTc3MTI2NzM5OSAsICJpYXQiIDogMTc3MTI2NzA5OSAsICJzeXN0ZW0iIDogIm1zIn0.AUqlgQ2p4T2zqeYBY8tPKfOxjOBo6YJGi6FxeLJ2tIQ
User-Agent: VIMS
c: application/sdp
l:    521

v=0
o=VIMS 234 1 IN IP4 109.61.92.230
s=VIMS
c=IN IP4 109.61.92.230
t=0 0
m=audio 15266 RTP/AVP 114 0 8 9 100 96 97 18 101
a=rtpmap:114 opus/48000/2
a=fmtp:114 minptime=10;useinbandfec=1;stereo=0;usedtx=1
a=rtcp-fb:114 transport-cc
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=rtpmap:9 G722/8000
a=rtpmap:100 ilbc/8000
a=rtpmap:96 AMR-WB/16000
a=rtpmap:97 AMR-WB/16000
a=fmtp:97 octet-align=1
a=rtpmap:18 G729/8000
a=rtpmap:101 telephone-event/8000
a=fmtp:101 0-15
a=sendrecv
a=rtcp:15267
a=ptime:20
2026-02-16 18:38:19.616  Received:
SIP/2.0 100 Trying
v: SIP/2.0/UDP 109.61.92.230:5090;rport=5090;received=109.61.92.230;branch=z9hG4bKPjf2af7869-bd50-4648-8d8d-47605f589a96
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
f: <sip:971525194521@zenith.bhycm.yeastarcloud.com>;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: <sip:971547055538@zenith.bhycm.yeastarcloud.com>
CSeq: 20762 INVITE
l: 0

2026-02-16 18:38:19.801  Received:
SIP/2.0 401 Unauthorized
v: SIP/2.0/UDP 109.61.92.230:5090;rport=5090;received=109.61.92.230;branch=z9hG4bKPjf2af7869-bd50-4648-8d8d-47605f589a96
Record-Route: <sip:3.147.160.14:5060;transport=UDP;lr>
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
f: <sip:971525194521@zenith.bhycm.yeastarcloud.com>;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: <sip:971547055538@zenith.bhycm.yeastarcloud.com>;tag=z9hG4bKa9f6.99ccb9f.0
CSeq: 20762 INVITE
WWW-Authenticate: Digest realm="YSAsterisk",nonce="1771267099/28f42a42bf90ee737b87fc08c38e4511",opaque="151d95da1e9a5407",algorithm=md5,qop="auth"
Server: Yeastar PCE
YSUser-Agent: YSBC 2.11.36
l: 0

2026-02-16 18:38:19.843  Received:
SIP/2.0 100 Trying
v: SIP/2.0/UDP 109.61.92.230:5090;rport=5090;received=109.61.92.230;branch=z9hG4bKPj1eeb3f13-33aa-4b40-a75f-0233593baa17
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
f: <sip:971525194521@zenith.bhycm.yeastarcloud.com>;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: <sip:971547055538@zenith.bhycm.yeastarcloud.com>
CSeq: 20763 INVITE
l: 0

2026-02-16 18:38:22.487  Received:
SIP/2.0 100 Trying
v: SIP/2.0/UDP 109.61.92.230:5090;rport=5090;received=109.61.92.230;branch=z9hG4bKPj1eeb3f13-33aa-4b40-a75f-0233593baa17
Record-Route: <sip:3.147.160.14:5060;transport=UDP;lr>
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
f: <sip:971525194521@zenith.bhycm.yeastarcloud.com>;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: <sip:971547055538@zenith.bhycm.yeastarcloud.com>
CSeq: 20763 INVITE
Server: Yeastar PCE
YSUser-Agent: YSBC 2.11.36
l: 0

2026-02-16 18:38:23.770  Received:
SIP/2.0 181 Call Is Being Forwarded
v: SIP/2.0/UDP 109.61.92.230:5090;rport=5090;received=109.61.92.230;branch=z9hG4bKPj1eeb3f13-33aa-4b40-a75f-0233593baa17
Record-Route: <sip:3.147.160.14:5060;transport=UDP;lr>
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
f: <sip:971525194521@zenith.bhycm.yeastarcloud.com>;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: <sip:971547055538@zenith.bhycm.yeastarcloud.com>;tag=7ac30d97-7472-4108-99a8-2ec6020068d2
CSeq: 20763 INVITE
m: <sip:zenith.bhycm.yeastarcloud.com:5060>
Server: Yeastar PCE
Allow: OPTIONS, NOTIFY, SUBSCRIBE, NOTIFY, PUBLISH, INVITE, ACK, BYE, CANCEL, UPDATE, REGISTER, REFER, MESSAGE
YSUser-Agent: YSBC 2.11.36
l: 0

2026-02-16 18:38:23.867  Received:
SIP/2.0 183 Session Progress
v: SIP/2.0/UDP 109.61.92.230:5090;rport=5090;received=109.61.92.230;branch=z9hG4bKPj1eeb3f13-33aa-4b40-a75f-0233593baa17
Record-Route: <sip:3.147.160.14:5060;transport=UDP;lr>
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
f: <sip:971525194521@zenith.bhycm.yeastarcloud.com>;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: <sip:971547055538@zenith.bhycm.yeastarcloud.com>;tag=7ac30d97-7472-4108-99a8-2ec6020068d2
CSeq: 20763 INVITE
m: <sip:zenith.bhycm.yeastarcloud.com:5060>
Server: Yeastar PCE
Allow: OPTIONS, NOTIFY, SUBSCRIBE, NOTIFY, PUBLISH, INVITE, ACK, BYE, CANCEL, UPDATE, REGISTER, REFER, MESSAGE
YSUser-Agent: YSBC 2.11.36
c: application/sdp
l:    265

v=0
o=- 234 3 IN IP4 15.184.229.124
s=Asterisk
c=IN IP4 15.184.229.124
t=0 0
a=rtpengine:9cd54464ffa3
m=audio 43968 RTP/AVP 0 101
a=maxptime:150
a=rtpmap:0 PCMU/8000
a=rtpmap:101 telephone-event/8000
a=fmtp:101 0-16
a=sendrecv
a=rtcp:43969
a=ptime:20
-----END SIP TRACE UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0

2026-02-16 18:38:23.870 Sent event to JS onPhoneEvent with params [{id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; name = Call.AudioStarted ; sipTransport = UDP ; headers = {} ; scheme = {endpoints = { = {audio = [{codecs = [0 ;  101 ;  ] ; direction = sendrecv ; flows = [{uniq = 0 ; } ;  ] ; options = {} ; type = audio ; uniq = 0 ; } ;  ] ; place = 0 ; type =  ; video = [] ; vox-params = [] ; } ; } ; } ; code = 183 ; } ;  ]
2026-02-16 18:38:24.081 Sent event to JS onPhoneEvent with params [{id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; name = Call.FirstAudioPacketReceived ; } ;  ]

-----BEGIN SIP TRACE UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 
2026-02-16 18:38:31.747  Received:
SIP/2.0 200 OK
v: SIP/2.0/UDP 109.61.92.230:5090;rport=5090;received=109.61.92.230;branch=z9hG4bKPj1eeb3f13-33aa-4b40-a75f-0233593baa17
Record-Route: <sip:3.147.160.14:5060;transport=UDP;lr>
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
f: <sip:971525194521@zenith.bhycm.yeastarcloud.com>;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: <sip:971547055538@zenith.bhycm.yeastarcloud.com>;tag=7ac30d97-7472-4108-99a8-2ec6020068d2
CSeq: 20763 INVITE
m: <sip:971547055538@zenith.bhycm.yeastarcloud.com:5060>
Server: Yeastar PCE
Allow: OPTIONS, NOTIFY, SUBSCRIBE, NOTIFY, PUBLISH, INVITE, ACK, BYE, CANCEL, UPDATE, REGISTER, REFER, MESSAGE
k: timer, replaces, norefersub
YSUser-Agent: YSBC 2.11.36
VI-Client-IP: 15.184.129.101
c: application/sdp
l:    265

v=0
o=- 234 3 IN IP4 15.184.229.124
s=Asterisk
c=IN IP4 15.184.229.124
t=0 0
a=rtpengine:9cd54464ffa3
m=audio 43968 RTP/AVP 0 101
a=maxptime:150
a=rtpmap:0 PCMU/8000
a=rtpmap:101 telephone-event/8000
a=fmtp:101 0-16
a=sendrecv
a=rtcp:43969
a=ptime:20
2026-02-16 18:38:31.747  Sent:
ACK sip:971547055538@zenith.bhycm.yeastarcloud.com:5060 SIP/2.0
v: SIP/2.0/UDP 109.61.92.230:5090;rport;branch=z9hG4bKPj66b6af42-6b0d-425d-9248-d5c66bcb094e
Max-Forwards: 70
f: sip:971525194521@zenith.bhycm.yeastarcloud.com;tag=VVVVV109.61.92.230_5090_df99e4f7781d3d21841bd83bc7813631
t: sip:971547055538@zenith.bhycm.yeastarcloud.com;tag=7ac30d97-7472-4108-99a8-2ec6020068d2
i: 87fb07c0-ab1d-42df-9618-2a4bc6372bb7
CSeq: 20763 ACK
Route: <sip:3.147.160.14:5060;transport=UDP;lr>
User-Agent: VIMS
l: 0

-----END SIP TRACE UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0

2026-02-16 18:38:31.750 Sent event to JS onPhoneEvent with params [{id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; name = Call.Connected ; sipCallId = 87fb07c0-ab1d-42df-9618-2a4bc6372bb7 ; sipTransport = UDP ; headers = {VI-Client-IP = 15.184.129.101 ; } ; scheme = {endpoints = { = {audio = [{codecs = [0 ;  101 ;  ] ; direction = sendrecv ; flows = [{uniq = 0 ; } ;  ] ; options = {} ; type = audio ; uniq = 0 ; } ;  ] ; place = 0 ; type =  ; video = [] ; vox-params = [] ; } ; } ; } ; displayName = 971547055538 ; encrypted = false ; } ;  ]
2026-02-16 18:38:31.762 Sent event to JS onPhoneEvent with params [{id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; name = Call.AudioQualityDetected ; quality = Standard ; } ;  ]
2026-02-16 18:38:31.781 Executing JS command: CreateWebSocket with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; } ;  wss://local/ultravox ;  {headers = ****** ; } ;  ]
2026-02-16 18:38:31.782 {"url":"wss://local/ultravox","onclose":null,"onerror":null,"onmessage":null,"onopen":null,"oncreated":null,"onmediastarted":null,"onmediaended":null,"readyState":"connecting","_id":"QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ"}
2026-02-16 18:38:31.782 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Created ; } ;  ]
2026-02-16 18:38:31.786 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Open ; } ;  ]
2026-02-16 18:38:31.786 Executing JS command: SendMediaBetween with params [{id1 = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; id2 = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; } ;  ]
2026-02-16 18:38:31.821 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"ConnectorInformation","payload":{"applicationVersion":"0.38.0","id":"e788dcd12ea00034acb1511b120dec54","endpoint":"/ultravox"}} ; } ;  ]
2026-02-16 18:38:32.456 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.MediaEventStarted ; tag =  ; encoding = PCM16 ; customParameters = NULL ; } ;  ]
2026-02-16 18:38:32.609 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"Hello","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:32.691 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":",","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:32.841 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" this","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:32.946 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" is","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:33.236 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" James","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:33.364 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" from","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:33.863 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" FastTrack","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:33.898 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":".","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:33.922 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" ","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.015 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":"How","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.143 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" can","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.189 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" I","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.355 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" help","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.502 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" you","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.618 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":"?","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.897 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"","delta":" ","final":false,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:34.897 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Message ; text = {"customEvent":"Transcript","payload":{"type":"transcript","role":"agent","medium":"voice","text":"Hello, this is James from FastTrack. How can I help you? ","final":true,"ordinal":0}} ; } ;  ]
2026-02-16 18:38:35.638 Sent event to JS onPhoneEvent with params [{id = UhxdDG64T3GvkbYRm-BIu0AbjBhS00_plaDbaPh4vc0 ; name = Call.Disconnected ; headers = {Reason = Q.850;cause=16 ; } ; direction = SIP Call ; duration = 4 ; cost = 0 ; internalCode = 16 ; } ;  ]
2026-02-16 18:38:35.687 Executing JS command: DestroyWebSocket with params [QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ;  ]
2026-02-16 18:38:35.687 Terminating request..., stack=VoxEngine.terminate@/voxengine.js:68:51
terminateSession@/SipBase:39:15
addSipCommonListeners/<@/SipBase:85:13
dispatchEvent@/__voxengine.js:543:32
Call/this.dispatchEvent@/call.js:384:48
Application/this.onPhoneEvent@/application.js:876:21
onPhoneEvent@/main.js:235:21
@/ line 1 > eval:1:13
JSession_onCall@/:1:80
2026-02-16 18:38:35.687 Executing JS command: terminating with params []
2026-02-16 18:38:35.687 Terminating (onClose)
2026-02-16 18:38:35.687 Terminating with exit code 0.
2026-02-16 18:38:35.687 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.MediaEventEnded ; tag =  ; mediaInfo = {duration = 2 ; } ; } ;  ]
2026-02-16 18:38:35.687 Sent event to JS onPhoneEvent with params [{id = QukaBuYlSuSQOcpf4F6WoUX24mrw3EB7onPl6p2bTQQ ; name = WebSocket.Close ; code = 1000 ; wasClean = true ; reason = Normal connection close ; } ;  ]
2026-02-16 18:38:35.744 Executing JS command: close with params {CpuMillis = 61 ; }
2026-02-16 18:38:35.744 Normal termination
2026-02-16 18:38:35.744 Session terminated
