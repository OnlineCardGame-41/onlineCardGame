## Architecture Overview

### 1. Static View
![Component](component-diagram.png)

| Component | Responsibility |
|-----------|----------------|
| Signalling Server | Lobby / ICE relay |
| CardGame Client | UI, rules, P2P sync |

Communication: Message over WebSocket → SDP/ICE → DataChannel.

### 2. Dynamic View
![Join Sequence](sequence-join-game.png)

Sequence illustrates signalling handshake, DTLS, game start.

### 3. Deployment View
![Deployment](deployment.png)

Nodes:
* **Player PC** – Godot export (`CardGame.exe`)
* **Public VPS** – Go binary 
* **STUN/TURN** – public service (fallback)

### 4. Technology Stack
| Layer | Tech |
|-------|------|
| Client | Godot 4.4 (GDScript) |
| Server | Go 1.24, WebSocket |
| CI/CD | GitHub Actions |
