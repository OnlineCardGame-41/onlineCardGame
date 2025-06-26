package pkg

import (
	"fmt"
	"time"
)
type LobbyId int
type PeerId int
type LocalId int

const (
	LOBBY_SEAL_GRACE_PERIOD = 10 * time.Second
)

type Hub struct {
	peers      map[PeerId]*Peer
	lobbies    map[LobbyId]*Lobby
	peer_lobby map[PeerId]LobbyId

	// Channels for messages
	connect    chan *Peer
	disconnect chan *Peer
	peer_msg   chan *PeerMsg
}

func NewHub() *Hub {
	return &Hub{
		peers:      make(map[PeerId]*Peer),
		lobbies:    make(map[LobbyId]*Lobby),
		peer_lobby: make(map[PeerId]LobbyId),

		connect:    make(chan *Peer),
		disconnect: make(chan *Peer),
		peer_msg:   make(chan *PeerMsg),
	}
}

// Handle hub messages
func (hub *Hub) Run() {
	fmt.Println("[Hub.Run]")

	defer func() {
		fmt.Println("[Hub.Run] exiting")
	}()

	for {
		// Close any sealed lobbies that have passed the grace period for joining
		for _, lobby := range hub.lobbies {
			if lobby.sealedAt.IsZero() {
				continue
			}

			if time.Since(lobby.sealedAt) > LOBBY_SEAL_GRACE_PERIOD {
				fmt.Println("[Hub.Run] Lobby fully sealed, closing all peers")
				for _, member := range lobby.members {
					member.close()
					delete(hub.peers, member.id)
				}
				delete(hub.lobbies, lobby.id)
				fmt.Printf("[Hub.Run] Lobby %d closed\n", int(lobby.id))
			} else {
				fmt.Println("[Hub.Run] Lobby sealed, waiting for grace period to expire")
			}
		}

		select {
		case <-time.After(1 * time.Second):
			// This case triggers every second when no other channel has activity
			// No action needed here; the loop will recheck the grace period

		case peer := <-hub.connect:
			fmt.Printf("[Hub.Run] <- connect peer %d\n", int(peer.id))
			hub.peers[peer.id] = peer

		case peer := <-hub.disconnect:
			fmt.Printf("[Hub.Run] <- disconnect peer %d\n", int(peer.id))
			delete(hub.peers, peer.id)

		case peer_msg := <-hub.peer_msg:
			source_peer := hub.peers[peer_msg.sourceId]
			if source_peer == nil {
				fmt.Printf("[Hub.Run] Peer not found %d\n", int(peer_msg.sourceId))
				continue
			}

			switch peer_msg.msg.msgType {
			case HOST:
				lobby := NewLobby(source_peer)
    				hub.lobbies[lobby.id] = lobby
    				hub.peer_lobby[source_peer.id] = lobby.id

    				// 2. Отвечаем хосту его ЛОКАЛЬНЫМ ID (=1)
    				source_peer.send <- msg(int(lobby.LocalId(source_peer)), CONNECTED, nil)
    				source_peer.send <- msg(int(lobby.id), HOST, nil)

			case JOIN:
				lobby, ok := hub.lobbies[LobbyId(peer_msg.msg.id)]
				if !ok{
					return
				}
    				localID := lobby.AddMember(source_peer)
    				hub.peer_lobby[source_peer.id] = lobby.id

    				isSealed := fmt.Sprintf("%t", !lobby.sealedAt.IsZero())
    				source_peer.send <- msg(int(localID), CONNECTED, nil)
    				source_peer.send <- msg(int(lobby.id), JOIN, []byte(isSealed))

    				// уведомляем всех остальных
    				for id, member := range lobby.members {
        				if id == localID {
            					continue
        				}
        				source_peer.send <- msg(int(id), PEER_CONNECT, nil)
        				member.send <- msg(int(localID), PEER_CONNECT, nil)
    				}

			// case LEAVE:
			// TODO: Handle leave

			case SEAL:
			    lobby := hub.lobbies[LobbyId(peer_msg.msg.id)]
			    if lobby == nil {
			        fmt.Println("[Hub.Run] Lobby not found")
			        continue
			    }
			    if lobby.hostGlobal != source_peer.id { // ← исправили
			        fmt.Println("[Hub.Run] Only host can seal lobby")
			        continue
			    }
			    if !lobby.sealedAt.IsZero() {
			        fmt.Println("[Hub.Run] Lobby already sealed")
			        continue
			    }
			    lobby.sealedAt = time.Now()
			
			    // рассылаем от имени локального ID хоста (=1)
			    for _, member := range lobby.members {
			        senderLocal := lobby.LocalId(source_peer)
			        member.send <- msg(int(senderLocal), SEAL, nil)
			    }

			case OFFER, ANSWER, CANDIDATE:
				lobbyID := hub.peer_lobby[source_peer.id]
    				lobby := hub.lobbies[lobbyID]
    				if lobby == nil {
        				fmt.Println("[Hub] Lobby not found")
        				continue
    				}

				// msg.id = локальный ID адресата
				targetLocal := LocalId(peer_msg.msg.id)
				targetPeer := lobby.PeerByLocal(targetLocal)
				if targetPeer == nil {
				fmt.Println("[Hub] Target peer not in lobby")
				    continue
				}
				
				// пересылаем, указав для получателя ЛОКАЛЬНЫЙ ID отправителя
				sourceLocal := lobby.LocalId(source_peer)
				targetPeer.send <- msg(int(sourceLocal), peer_msg.msg.msgType, peer_msg.msg.data)
			case LOBBIES:
				for _, lobby := range hub.lobbies {
				    source_peer.send <- msg(int(lobby.id), LOBBIES, []byte(lobby.members[1].name));
				}
			case UPDATENAME:
				source_peer.UpdateName(string(peer_msg.msg.data))

			}
		}
	}
}
