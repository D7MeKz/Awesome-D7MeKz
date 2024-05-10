package main

import (
	"circuit-breaker/retry"
	"context"
	"fmt"
	"time"
)

var count int = 0

func EmulateTransientError(ctx context.Context) (string, error) {
	count++

	if count <= 3 {
		return "fail", fmt.Errorf("error")
	} else {
		return "success", nil
	}
}
func main() {
	r := retry.Retry(EmulateTransientError, 5, 2*time.Second)
	res, err := r(context.Background())
	fmt.Println(res, err)
}
