package main

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"
)

// Effector is the function that communicate with the external service.
type Effector func(ctx context.Context) (string, error)

func Retry(effector Effector, retires int, delay time.Duration) Effector {
	return func(ctx context.Context) (string, error) {
		for r := 0; ; r++ {
			response, err := effector(ctx)
			// Succcess
			if err == nil || r >= retires {
				return response, err
			}

			log.Printf("Attempt %d failed, retrying in %v", r+1, delay)
			select {
			case <-time.After(delay):
			case <-ctx.Done(): // End of the context
				return "", ctx.Err()
			}
		}
	}
}

func Throttle(e Effector, max uint, refill uint, d time.Duration) Effector {
	var tokens = max
	var once sync.Once

	return func(ctx context.Context) (string, error) {
		if ctx.Err() != nil {
			return "", ctx.Err()
		}

		once.Do(func() {
			ticker := time.NewTicker(d)

			go func() {
				defer ticker.Stop()

				for {
					select {
					case <-ctx.Done():
						return
					case <-ticker.C:
						t := tokens + refill
						if t > max {
							t = max
						}
						tokens = t
					}

				}
			}()
		})

		if tokens <= 0 {
			return "", fmt.Errorf("too many calls")
		}
		tokens--
		fmt.Println("Tokens:", tokens)

		return e(ctx)
	}
}
