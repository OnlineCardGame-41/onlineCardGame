[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![Unlicense License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

# OnlineCardGame


**Real‑time peer‑to‑peer card battles in your phone and on desktop.**

[Build](https://github.com/OnlineCardGame-41/onlineCardGame/releases/tag/MVP2.5)  [Demo Video](https://drive.google.com/file/d/16F4Y66ZWBoXNq-1EIaNqmYuY29p4Isc4/view?usp=sharing)

---

## Project Goals & Description

Build a lightweight, cross‑platform card game that:

- Delivers <50 ms end‑to‑end latency in casual matches
- Requires **zero server state** beyond lobby orchestration
- Allows to play a fun game with good balance

---


## Feature Roadmap

| Feature           | Status            |
| ----------------- | ----------------- |
| Join / host lobby | - [x] Implemented |
| Gameplay          | - [x] Implemented |
| UI                | - [ ] Planned     |
| Mobile Version    | - [ ] Planned     |

---

## Usage

The **MVP v2** is distributed as a self-contained Windows build produced by the CI pipeline.

1. Open the **Actions → _CI+CD_** workflow in GitHub and select the **latest green run**.  
2. Download the artifact **`CardGame-windows`**.  
3. Extract the ZIP archive to any local directory (no installation required).  
4. Double-click `CardGame.exe`.  
   The game will start and automatically connect to the public signalling server 

> _Advanced_: To build from source you need Go 1.24+, Godot 4.4, and the Godot export templates.  
> Run `go run ./server/cmd` to launch the signalling server and `godot --export-release "Windows Desktop"` from the **CardGame** folder to rebuild the client.
---

## Installation / Deployment

To build from source you need **Go 1.24+**, **Godot 4.4**, and the Godot export templates installed.  
Clone the repo, run `go run ./server/cmd` to start the signalling server, then from the `CardGame` folder execute

```bash
godot --export-release "Windows Desktop"
```

to produce `CardGame.exe`. Drop the binary onto any Windows 10+ machine and connect it to the same LAN or make the server publicly reachable on ports 80/443 (TCP) and 3478 (UDP).

# I'm not copying and pasting without reading
---

## Documentation

    
- [Kanban board](https://github.com/orgs/OnlineCardGame-41/projects/2)
        
        
- [**Secrets Management**](docs/secrets-management.md)
    
- [**Quality Attributes & Scenarios**](docs/quality-assurance/quality-attribute-scenarios.md)
    
- **Quality Assurance**
    
    - [Automated tests](docs/quality-assurance/automated-tests.md)
        
    - [User acceptance tests](docs/quality-assurance/user-acceptance-tests.md)
         
- **Automation**
    
    - [Continuous Integration](docs/automation/continuous-integration.md)
    - 
- [**Architecture**](docs/architecture/architecture.md)
   - [Static view](docs/architecture/component-diagram.png)
   - [Dynamic view](docs/architecture/sequence-join-game.png)
   - [Deployment view](docs/architecture/deployment.png)
---

## Quality Assurance

| Layer            | Tooling                       | Test Types          |
| ---------------- | ----------------------------- | ------------------- |
| **Go server**    | `go test`                     | Unit & integration  |
| **Godot client** | **GUT**, `gdlint`, `gdformat` | Unit & integration  |
| **CI pipeline**  | GitHub Actions                | Lint, test, package |

---

## Build & Deployment Automation

|Stage|Tool / File|Purpose|
|---|---|---|
|**CI**|.github/workflows/main.yml|Lint, test, package|
|**CD**|GitHub Actions artefacts|Publish `CardGame-windows.zip`|

Each successful run attaches a fresh Windows artefact which can be downloaded from the **Actions → CI+CD** tab.

---

## Architecture Overview

### Static View

![Component Diagram](docs/architecture/component-diagram.png)

|Component|Responsibility|Tech|
|---|---|---|
|**Signalling Server**|Lobby management, matchmaking, SDP/ICE relay|Go 1.24, WebSocket|
|**CardGame Client**|Game logic, rendering, WebRTC data‑channel|Godot 4.4|
|**WebRTC DataChannel**|Real‑time state sync|Built‑in WebRTC|

### Dynamic View

![Join Sequence](docs/architecture/sequence-join-game.png)

Average time from lobby click to open data channel: **3.0 s** (measured via `OS.get_ticks_msec()` on both peers).

### Deployment View

![Deployment Diagram](docs/architecture/deployment.png)

|Node|Artefact|Notes|
|---|---|---|
|**Player PC**|`CardGame.exe`|Self‑contained|
|**Public VPS**|`signalling-server` binary / Docker|Ports 80/443 TCP, 3478 UDP|

### Tech Stack

See docs/architecture/architecture.md for full details.

---


[contributors-shield]: https://img.shields.io/github/contributors/OnlineCardGame-41/onlineCardGame.svg?style=for-the-badge
[contributors-url]: https://github.com/OnlineCardGame-41/onlineCardGame/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/OnlineCardGame-41/onlineCardGame.svg?style=for-the-badge
[forks-url]: https://github.com/OnlineCardGame-41/onlineCardGame/network/members
[stars-shield]: https://img.shields.io/github/stars/OnlineCardGame-41/onlineCardGame.svg?style=for-the-badge
[stars-url]: https://github.com/OnlineCardGame-41/onlineCardGame/stargazers
[issues-shield]: https://img.shields.io/github/issues/OnlineCardGame-41/onlineCardGame.svg?style=for-the-badge
[issues-url]: https://github.com/OnlineCardGame-41/onlineCardGame/issues
[license-shield]: https://img.shields.io/github/license/OnlineCardGame-41/onlineCardGame.svg?style=for-the-badge
[license-url]: https://github.com/OnlineCardGame-41/onlineCardGame/blob/main/LICENSE.txt

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/othneildrew

[product-screenshot]: images/screenshot.png

[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com

