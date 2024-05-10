package breaker

import (
	"context"
	"errors"
	"sync"
	"time"
)

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
