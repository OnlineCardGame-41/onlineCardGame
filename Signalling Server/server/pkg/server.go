package pkg

import (
	"fmt"
	"time"

	"github.com/gorilla/websocket"
)

const (
	READ_TIMEOUT  = 60 * time.Second
	WRITE_TIMEOUT = 10 * time.Second
	// Interval for sending ping messages to WebSocket connections. Needs to be
	// less than the read timeout for the connection.
	PING_INTERVAL = (READ_TIMEOUT * 9) / 10
)

var (
	NEW_LINE = []byte{'\n'}
)

type Server struct {
	hub *Hub
}

type Diagnostics struct {
	Lobbies []LobbyId
	Peers   []PeerId
}

// Initialize a Hub and start listening for messages
func (server *Server) Run() {
	server.hub = NewHub()
	go server.hub.Run()
}

// Initialize a Peer for a WebSocket connection.
func (server *Server) InitPeer(ws *websocket.Conn) {
	peer := NewPeer(ws)

	go peerToHub(peer, server.hub)
	go peerToWs(peer)
}

// Get a summary of the current state of the server.
func (server *Server) GetDiagnostics() *Diagnostics {
	lobbies := make([]LobbyId, 0, len(server.hub.lobbies))
	peers := make([]PeerId, 0, len(server.hub.peers))

	for id := range server.hub.lobbies {
		lobbies = append(lobbies, id)
	}

	for id := range server.hub.peers {
		peers = append(peers, id)
	}

	return &Diagnostics{
		Lobbies: lobbies,
		Peers:   peers,
	}
}

// Next read deadline for the WebSocket connection is now + READ_TIMEOUT.
func nextDeadline(timeout time.Duration) time.Time {
	return time.Now().Add(timeout)
}

// Connect a peer to the hub and pump WebSocket messages from peer to hub.
// Disconnect from hub and close WebSocket when done.
func peerToHub(peer *Peer, hub *Hub) {
	fmt.Println("[Server.peerToHub]")

	defer func() {
		fmt.Println("[Server.peerToHub] exiting")
		hub.disconnect <- peer
		peer.close()
	}()

	hub.connect <- peer

	// Set read deadline for the WebSocket connection and reset it every time a
	// message is received.
	peer.ws.SetReadDeadline(nextDeadline(READ_TIMEOUT))
	peer.ws.SetPongHandler(func(string) error {
		peer.ws.SetReadDeadline(nextDeadline(READ_TIMEOUT))
		return nil
	})

	fmt.Println("[Server.peerToHub] Starting message loop")

	for {
		fmt.Println("[Server.peerToHub] Reading message")
		_, msg, err := peer.ws.ReadMessage()
		if err != nil {
			// Closing the ws connection will happen when a ReadMessage() is
			// already in progress. If we find peer.isClosed is true, we can
			// assume the connection was closed by calling peer.close().
			if peer.isClosed {
				fmt.Println("[Server.peerToHub] Peer closed")
				return
			}

			fmt.Println("[Server.peerToHub] Error reading message:", err)

			break
		}

		fmt.Println("[Server.peerToHub] msg:", string(msg))
		hub.peer_msg <- NewPeerMsg(peer.id, msg)
	}
}

// Sends messages from the Peer.send channel to the WebSocket connection.
// The Hub sends messages to the Peer.send channel.
func peerToWs(peer *Peer) {
	pinger := time.NewTicker(PING_INTERVAL)
	defer func() {
		fmt.Println("[Server.peerToWs] exiting")
		pinger.Stop()
		peer.close()
	}()

	for {
		select {
		case <-peer.closed:
			fmt.Println("[Server.peerToWs] Peer closed")
			return

		case msg, ok := <-peer.send:
			if !ok {
				fmt.Println("[Server.peerToWs] Peer send channel closed")
				peer.ws.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			// It's possible we have queued messages waiting, so flush all of
			// them.
			for {
				peer.ws.SetWriteDeadline(nextDeadline(WRITE_TIMEOUT))

				err := peer.ws.WriteMessage(websocket.TextMessage, msg)
				if err != nil {
					fmt.Println("[Server.peerToWs] Error writing message:", err)
					return
				}

				if len(peer.send) == 0 {
					break
				}

				msg = <-peer.send
			}

		// Ping the WebSocket connection to keep it alive. Update the write timeout.
		case <-pinger.C:
			peer.ws.SetWriteDeadline(nextDeadline(WRITE_TIMEOUT))
			if err := peer.ws.WriteMessage(websocket.PingMessage, nil); err != nil {
				fmt.Println("[Server.peerToWs] Error writing ping message:", err)
				return
			}
		}
	}
}
