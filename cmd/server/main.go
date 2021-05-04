package main

import (
	"fmt"

	"github.com/rosylilly/gochat"
)

func main() {
	fmt.Printf("v%s-%s", gochat.VERSION, gochat.REVISION)
}
