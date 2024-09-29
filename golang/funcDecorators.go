package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

// 普通装饰器

type Handler func(w http.ResponseWriter,r *http.Request)

func Logger(handler Handler) Handler {
	return func(w http.ResponseWriter,r *http.Request) {
		now := time.Now()
		handler(w,r)
		log.Printf("url:%s elase:%v",r.URL,time.Since(now))
	}
}

func Hello(w http.ResponseWriter,r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("hello"))
}

func HowAreYou(w http.ResponseWriter,r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("how are you"))
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /hello",Logger(Hello))
	mux.HandleFunc("GET /how",Logger(HowAreYou))
	srv := http.Server{
		Addr: ":8080",
		Handler: mux,
	}
	fmt.Printf("addr:%s",srv.Addr)
}