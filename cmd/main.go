package main

import (
	"github.com/spf13/viper"
	"github.com/xiaomeng79/grpc-example/srv"
)

func main() {
	viper.SetDefault("port", "8080")
	port := viper.GetString("port")
	srv.Run(port)
}
