import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgiton_ble_sdk/kgiton_ble_sdk.dart';

void main() {
  group('RetryExecutor', () {
    test('should succeed on first attempt', () async {
      int attempts = 0;
      
      final result = await RetryExecutor.execute(
        operation: () async {
          attempts++;
          return 'success';
        },
        policy: RetryPolicy.defaultPolicy,
      );

      expect(result, 'success');
      expect(attempts, 1);
    });

    test('should retry on failure and eventually succeed', () async {
      int attempts = 0;
      
      final result = await RetryExecutor.execute(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Temporary failure');
          }
          return 'success';
        },
        policy: RetryPolicy(maxAttempts: 3, initialDelay: Duration(milliseconds: 10)),
      );

      expect(result, 'success');
      expect(attempts, 3);
    });

    test('should throw after max attempts', () async {
      int attempts = 0;
      
      expect(
        () => RetryExecutor.execute(
          operation: () async {
            attempts++;
            throw Exception('Permanent failure');
          },
          policy: RetryPolicy(maxAttempts: 3, initialDelay: Duration(milliseconds: 10)),
        ),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 200));
      expect(attempts, 3);
    });

    test('should respect retryIf condition', () async {
      int attempts = 0;
      
      expect(
        () => RetryExecutor.execute(
          operation: () async {
            attempts++;
            throw FormatException('Not retryable');
          },
          policy: RetryPolicy(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
            retryIf: (e) => e is! FormatException,
          ),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(attempts, 1); // Should not retry
    });

    test('should timeout operation', () async {
      expect(
        () => RetryExecutor.executeWithTimeout(
          operation: () => Future.delayed(Duration(seconds: 10)),
          timeout: Duration(milliseconds: 100),
          policy: RetryPolicy.noRetry,
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('ConnectionConfig', () {
    test('production config should have auto-reconnect enabled', () {
      expect(ConnectionConfig.production.autoReconnect, true);
      expect(ConnectionConfig.production.enableKeepAlive, true);
    });

    test('development config should have minimal features', () {
      expect(ConnectionConfig.development.autoReconnect, false);
      expect(ConnectionConfig.development.enableKeepAlive, false);
    });

    test('aggressive config should have high retry count', () {
      expect(ConnectionConfig.aggressive.maxReconnectAttempts, greaterThan(3));
    });
  });
}
