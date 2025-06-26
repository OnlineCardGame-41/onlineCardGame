package pkg

import (
	"fmt"

	"github.com/gorilla/websocket"
)

type Peer struct {
	id       PeerId
	name	 string
	ws       *websocket.Conn
	send     chan []byte
	closed   chan struct{}
	isClosed bool
}

func (peer *Peer) close() {
	if peer.isClosed {
		return
	}
	fmt.Println("[Peer.close] Closing peer", int(peer.id))
	peer.isClosed = true
	close(peer.closed)
	peer.ws.Close()
}

func NewPeer(ws *websocket.Conn) *Peer {
	return &Peer{
		id:     PeerId(NewID()),
		name: "Anonymous",
		ws:     ws,
		closed: make(chan struct{}),
		// Buffered channel
		send: make(chan []byte, 256),
	}
}

func (peer *Peer) UpdateName(name string) {
	if name == "" {
		return
	}
	peer.name = name
}
