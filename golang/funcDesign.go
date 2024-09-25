package main

import (
	"fmt"
)

type Server struct {
	Addr string
	Port string
}

type Option func(*Server)

func WithAddr(addr string) Option {
	return func(s *Server) {
		s.Addr = addr
	}
}

func WithPort(port string) Option {
	return func(s *Server) {
		s.Port = port
	}
}

func NewServer(options ...Option) *Server {
	srv := &Server{
		Addr: "localhost",
		Port: ":8080",
	}

	for _, option := range options {
		option(srv)
	}

	return srv
}

func mian() {
	srv := NewServer(WithAddr("192.168.1.1"))
	fmt.Println(srv)
}
