package pkg

import "time"

type Lobby struct {
	id       LobbyId
	hostGlobal     PeerId
	members  map[LocalId]*Peer
	global2local map[PeerId]LocalId
	local2global map[LocalId]PeerId
	sealedAt time.Time
}

func NewLobby(host *Peer) *Lobby {
	L := &Lobby{
		id:      LobbyId(NewID()),
		hostGlobal:    host.id,
		members:      make(map[LocalId]*Peer),
    		global2local: make(map[PeerId]LocalId),
    		local2global: make(map[LocalId]PeerId),
	}
	L.members[1] = host;
	L.global2local[host.id] = 1
	L.local2global[1] = host.id
	return L;
}

func (L *Lobby) AddMember(p *Peer) LocalId {
  var next LocalId = 2
  for {
    if _, ok := L.members[next]; !ok {
      break
    }
    next++
  }
  L.members[next] = p
  L.global2local[p.id] = next
  L.local2global[next] = p.id
  return next
}

func (L *Lobby) LocalId(p *Peer) LocalId {
	return L.global2local[p.id] 
}

func (L *Lobby) PeerByLocal(id LocalId) *Peer {
	return L.members[id] 
}
