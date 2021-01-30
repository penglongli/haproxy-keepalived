package main

import "github.com/penglongli/haproxy-keepalived/server"

func main() {
	if err := server.NewCommand().Execute(); err != nil {
		panic(err)
	}
}
