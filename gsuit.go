package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"os"
	"os/exec"
)

type Program struct {
	Host string `json:"host"`
	Port string `json:"port"`
}

var (
	network net.Listener
	program *Program
	version string
)

func init() {
	program = new(Program)
	version = "0.0.1"
}

func main() {
	if data, err := ioutil.ReadFile("config.json"); err == nil {
		json.Unmarshal(data, &program)
	} else {
		log.Fatal(err)
	}

	if tcp, err := net.Listen("tcp", fmt.Sprintf("%s:%s", program.Host, program.Port)); err == nil {
		network = tcp
	} else {
		log.Fatal(err)
	}

	refresh()

	for {
		conn, err := network.Accept()
		if err != nil {
			log.Fatal(err)
		}
		go printout(conn)
	}
}

func printout(conn net.Conn) {
	recv := make([]byte, 8)
	for {
		msg, err := conn.Read(recv)
		if err != nil {
			conn.Close()
			refresh()
			return
		}
		fmt.Println(string(recv[:msg]))
	}
}

func refresh() {
	cmd := exec.Command("cmd", "/c", "cls")
	cmd.Stdout = os.Stdout
	cmd.Run()

	fmt.Printf("GSUIT TCP SERVER %s (%s:%s)\n", version, program.Host, program.Port)
}
