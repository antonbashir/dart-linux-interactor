import 'configuration.dart';

class InteractorDefaults {
  InteractorDefaults._();

  static InteractorWorkerConfiguration worker() => InteractorWorkerConfiguration(
        trace: false,
        buffersCount: 4096,
        bufferSize: 4096,
        ringSize: 16384,
        ringFlags: 0,
        timeoutCheckerPeriod: Duration(milliseconds: 500),
        baseDelay: Duration(microseconds: 10),
        maxDelay: Duration(seconds: 5),
        delayRandomizationFactor: 0.25,
        cqePeekCount: 1024,
        cqeWaitCount: 1,
        cqeWaitTimeout: Duration(milliseconds: 1),
      );
}
