import 'configuration.dart';

class InteractorDefaults {
  InteractorDefaults._();

  static InteractorConfiguration worker() => InteractorConfiguration(
        staticBuffersCapacity: 4096,
        staticBufferSize: 4096,
        ringSize: 16384,
        ringFlags: 0,
        baseDelay: Duration(microseconds: 10),
        maxDelay: Duration(seconds: 5),
        delayRandomizationFactor: 0.25,
        cqePeekCount: 1024,
        cqeWaitCount: 1,
        cqeWaitTimeout: Duration(milliseconds: 1),
        memorySlabSize: 64 * 1024,
        memoryPreallocationSize: 64 * 1024,
        memoryQuotaSize: 16 * 1024 * 1024,
      );
}
