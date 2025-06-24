package pkg

import (
	"fmt"
	"strconv"
	"strings"
)

type MessageType int

const (
	INVALID MessageType = iota
	CONNECTED
	HOST
	JOIN
	PEER_CONNECT
	PEER_DISCONNECT
	OFFER
	ANSWER
	CANDIDATE
	SEAL
)

type Msg struct {
	id      int
	msgType MessageType
	data    []byte
}

type PeerMsg struct {
	sourceId PeerId
	msg      *Msg
}

// Deserialize Msg from a byte array.
func deserializeMsg(msgSerialized []byte) *Msg {
	tokens := strings.Split(string(msgSerialized), "|")
	fmt.Println("[Msg] tokens:", tokens)

	id, err := strconv.Atoi(tokens[1])
	if err != nil {
		fmt.Println("[Msg] Error parsing id:", err)
		return nil
	}

	msgType, err := strconv.Atoi(tokens[0])
	if err != nil {
		fmt.Println("[Msg] Error parsing msgType:", err)
		return nil
	}

	return &Msg{
		id:      id,
		msgType: MessageType(msgType),
		data:    []byte(strings.Join(tokens[2:], "|")),
	}
}

// Create a new Msg with the given id, msgType, and data.
func NewMsg(id int, msgType MessageType, data []byte) *Msg {
	return &Msg{
		id:      id,
		msgType: msgType,
		data:    data,
	}
}

func msg(id int, msgType MessageType, data []byte) []byte {
	return []byte(fmt.Sprintf("%d|%d|%s", int(msgType), id, string(data)))
}

// Create a new Msg with the given sourceId and payload.
func NewPeerMsg(sourceId PeerId, msgSerialized []byte) *PeerMsg {
	return &PeerMsg{
		sourceId: sourceId,
		msg:      deserializeMsg(msgSerialized),
	}
}
