package main

import (
	"encoding/json"
	"flag"
	"log"
	"net/http"

	".com/emeraldwalk/signalwsgo/pkg"
	".com/emeraldwalk/signalwsgo/static"
	"github.com/gorilla/websocket"
)

var port = flag.String("port", ":9000", "http port")
var certName = flag.String("cert", "", "certificate name")

// TODO: figure out largest expected message size
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Temporary for testing
	},
}

func main() {
	flag.Parse()

	server := &pkg.Server{}
	server.Run()

	http.Handle("/", http.FileServer(http.FS(static.Assets)))
	http.HandleFunc("/admin", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(server.GetDiagnostics())
	})
	http.HandleFunc("/test", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "test.html")
	})
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		ws, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Println(err)
		}

		server.InitPeer(ws)
	})

	isHttps := *certName != ""

	protocol := "http"
	if isHttps {
		protocol = "https"
	}

	log.Printf("Starting server on %s://localhost%s", protocol, *port)
	var err error
	if isHttps {
		err = http.ListenAndServeTLS(*port, *certName+".crt", *certName+".key", nil)
	} else {
		err = http.ListenAndServe(*port, nil)
	}

	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
