package breaker

import "context"

type Circuit func(ctx context.Context) (string, error)
