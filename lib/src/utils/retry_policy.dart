import 'dart:async';

/// Configuration for retry logic
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(Exception)? retryIf;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
    this.retryIf,
  });

  /// Default retry policy for BLE operations
  static const defaultPolicy = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 5),
  );

  /// Aggressive retry policy for critical operations
  static const aggressivePolicy = RetryPolicy(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 200),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 3),
  );

  /// No retry policy
  static const noRetry = RetryPolicy(maxAttempts: 1);
}

/// Retry utility for executing operations with exponential backoff
class RetryExecutor {
  /// Execute a function with retry logic
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    RetryPolicy policy = RetryPolicy.defaultPolicy,
    String? operationName,
  }) async {
    int attempt = 0;
    Duration currentDelay = policy.initialDelay;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (e) {
        if (attempt >= policy.maxAttempts) {
          rethrow;
        }

        // Check if should retry this exception
        if (policy.retryIf != null && e is Exception && !policy.retryIf!(e)) {
          rethrow;
        }

        // Wait before retry
        await Future.delayed(currentDelay);

        // Calculate next delay with exponential backoff
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * policy.backoffMultiplier)
              .round(),
        );

        if (currentDelay > policy.maxDelay) {
          currentDelay = policy.maxDelay;
        }
      }
    }
  }

  /// Execute with timeout and retry
  static Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    RetryPolicy policy = RetryPolicy.defaultPolicy,
    String? operationName,
  }) async {
    return await execute(
      operation: () => operation().timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Operation ${operationName ?? 'unknown'} timed out after ${timeout.inSeconds}s',
        ),
      ),
      policy: policy,
      operationName: operationName,
    );
  }
}
