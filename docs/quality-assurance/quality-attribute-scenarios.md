### 1. Performance Efficiency

| Sub-characteristic  | Source                 | Stimulus                     | Artifact           | Environment                               | Response                                                   | Response measure                                                        |
| ------------------- | ---------------------- | ---------------------------- | ------------------ | ----------------------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------- |
| Time behaviour      | Player                 | Presses **“Confirm move”**   | Client + P2P link  | 1-on-1 match, stable Wi-Fi ≥ 20 Mbps       | Peer sends move packet, opponent sees its animation        | End-to-end latency ≤ 150 ms for 95 % of moves                           |
| Resource utilisation| Profiling system       | 30-minute game session       | Android client     | Battery 50 %, 8-core CPU, 4 GB RAM         | Engine maintains average CPU load                          | ≤ 15 % average CPU and ≤ 250 MB RSS                                     |
| Capacity            | 1 000 players          | Peak concurrent users        | Signalling server  | VPS 2 vCPU / 4 GB RAM                     | WebRTC rooms are created                                   | ≥ 400 simultaneous tables without signal-time degradation (≤ 1 s)        |

---

### 2. Compatibility

| Sub-characteristic | Source          | Stimulus                                        | Artifact          | Environment                                   | Response                                   | Response measure                                 |
| ------------------ | --------------- | ----------------------------------------------- | ----------------- | --------------------------------------------- | ------------------------------------------ | ------------------------------------------------ |
| Interoperability   | Player (Android)| Connects to a table created on Windows          | Two Godot clients | Different OSs, NAT network conditions         | Exchange SDP/ICE, game starts              | Handshake completes ≤ 2 s, success rate ≥ 99 %    |
| Co-existence       | Operating system| Video-call app running concurrently             | Game client       | Mobile device with another WebRTC application | Game limits channel bit-rate               | Average share of bandwidth ≤ 40 %                |

---

### 3. Reliability

| Sub-characteristic | Source             | Stimulus                                | Artifact          | Environment                 | Response                                             | Response measure                          |
| ------------------ | ------------------ | --------------------------------------- | ----------------- | --------------------------- | ---------------------------------------------------- | ----------------------------------------- |
| Availability       | Player             | Opens lobby                             | Signalling server | 24 × 7 operation            | Returns table list                                   | Availability ≥ 99.8 % per month           |
| Fault tolerance    | Network            | 10 % packet loss for 5 s                | P2P link          | Match in progress           | Missing state frames are re-requested                | Game continues without disconnect; skipped moves = 0 |
| Recoverability     | ISP                | Connection drop for 30 s                | Client            | Mobile 4G → Wi-Fi           | Client reconnects and restores the game             | Full recovery ≤ 10 s, lost moves = 0      |

---

### 4. Security

| Sub-characteristic | Source                 | Stimulus                  | Artifact          | Environment  | Response                            | Response measure                                          |
| ------------------ | ---------------------- | ------------------------- | ----------------- | ------------ | ----------------------------------- | --------------------------------------------------------- |
| Confidentiality    | Malicious sniffer      | Passively listens traffic | P2P data          | Public Wi-Fi | DTLS encrypts the channel           | Impossible to extract card contents (probability < 10⁻⁶)  |
| Integrity          | Man-in-the-Middle att. | Substitutes move packet   | P2P link          | In-transit   | Client rejects packet via HMAC      | 100 % of attacks detected, game continues                 |
| Authenticity       | Player                 | Logs into account         | Signalling server | OAuth2 + JWT | Verifies token and issues ICE creds | Invalid tokens rejected ≤ 100 ms; false positives < 0.1 % |

---

### 5. Flexibility / Portability

| Sub-characteristic | Source   | Stimulus                                     | Artifact        | Environment            | Response                                 | Response measure                                          |
| ------------------ | -------- | -------------------------------------------- | --------------- | ---------------------- | ---------------------------------------- | --------------------------------------------------------- |
| Adaptability       | Producer | Web version required                         | Game repository | CI/CD, Emscripten      | Build to WebAssembly                     | Successful build with no code changes, ≤ 2 days           |
| Installability     | New user | Clicks **“Install”** on Steam                | Distribution    | Windows 11             | Client downloads and launches            | Successful installation ≥ 99 %, first window ≤ 15 s        |
| Replaceability     | DevOps   | Migrate signalling server to another VPS     | Docker container| Zero-downtime deploy   | Old traffic drained, new instance up     | Match downtime = 0 s; rollback ≤ 1 click                   |
