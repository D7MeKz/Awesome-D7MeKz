package retry

import "context"

// Effector is the function that communicate with the external service.
type Effector func(ctx context.Context) (string, error)
