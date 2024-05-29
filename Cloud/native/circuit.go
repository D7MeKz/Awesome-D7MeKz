package main

import (
	"context"
	"errors"
	"sync"
	"time"
)

type Circuit func(ctx context.Context) (string, error)

// Breaker는
// failureThreshold: 실패 임계값(open 상태로 전환되는 실패 횟수)
func Breaker(circuit Circuit, failureThreshold uint) Circuit {
	// consecutiveFailures: 연속 실패 횟수
	var consecutiveFailures int = 0
	// lastAttempt: 마지막 시도 시간
	var lastAttempt = time.Now()
	// m: 뮤텍스
	var m sync.RWMutex

	return func(ctx context.Context) (string, error) {
		// 읽기 잠금 수행
		m.RLock()

		// Check failure threshold is over.
		d := consecutiveFailures - int(failureThreshold)
		if d >= 0 {
			// You should wait 2^d seconds before retrying.
			shouldRetryAt := lastAttempt.Add(time.Second * 2 << uint(d))
			if !time.Now().After(shouldRetryAt) {
				m.RUnlock()
				return "", errors.New("service unreachable")
			}
		}

		// 읽기 잠금 해제
		m.RUnlock()

		// request property
		response, err := circuit(ctx)

		// Lock shared resource
		m.Lock()
		defer m.Unlock()

		// Set last attempt time
		lastAttempt = time.Now()

		if err != nil {
			consecutiveFailures++
			return response, err
		}

		// Init consecutiveFailures
		consecutiveFailures = 0

		return response, nil
	}

}

func First(circuit Circuit, d time.Duration) Circuit {
	// 연속된 마지막 호출 시간
	var threshold time.Time
	var result string
	var err error
	var m sync.Mutex

	return func(ctx context.Context) (string, error) {
		m.Lock()
		defer func() {
			threshold = time.Now().Add(d) // 업데이트
			m.Unlock()
		}()

		if time.Now().Before(threshold) {
			return result, err
		}

		result, err = circuit(ctx)
		return result, err
	}
}

func Last(circuit Circuit, d time.Duration) Circuit {
	var threshold time.Time
	var ticker *time.Ticker
	var result string
	var err error
	var once sync.Once
	var m sync.Mutex

	return func(ctx context.Context) (string, error) {
		m.Lock()
		defer m.Unlock()

		threshold = time.Now().Add(d)
		// 포함된 함수가 정확히 한번만 실행되도록 보장
		once.Do(func() {
			ticker = time.NewTicker(time.Millisecond * 100)

			go func() {
				// 끝날때 쯤에 ticker.Stop() 호출
				defer func() {
					m.Lock()
					ticker.Stop()
					once = sync.Once{} // 초기화
					m.Unlock()
				}()

				for {
					select {
					case <-ticker.C: // C is channel on which the ticks are delivered
						m.Lock()
						if time.Now().After(threshold) {
							result, err = circuit(ctx)
							m.Unlock()
							return
						}
						m.Unlock()
					case <-ctx.Done():
						m.Lock()
						result, err = "", ctx.Err()
						m.Unlock()
						return
					}
				}
			}()
		})

		return result, err

	}
}
