package main

import (
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
	effector := func(ctx context.Context) (string, error) {
		return "effect", nil
	}

	throttledEffector := Throttle(effector, 5, 1, time.Second)

	ctx := context.Background()
	for i := 0; i < 10; i++ {
		result, err := throttledEffector(ctx)
		if err != nil {
			fmt.Println("Error:", err)
		} else {
			fmt.Println("Result:", result)
		}
		time.Sleep(200 * time.Millisecond)
	}
}
