class InteractorConfiguration {
  final int staticBuffersCapacity;
  final int staticBufferSize;
  final int ringSize;
  final int ringFlags;
  final double delayRandomizationFactor;
  final int cqePeekCount;
  final int cqeWaitCount;
  final Duration cqeWaitTimeout;
  final Duration baseDelay;
  final Duration maxDelay;
  final int memorySlabSize;
  final int memoryPreallocationSize;
  final int memoryQuotaSize;

  InteractorConfiguration({
    required this.staticBuffersCapacity,
    required this.staticBufferSize,
    required this.ringSize,
    required this.ringFlags,
    required this.delayRandomizationFactor,
    required this.baseDelay,
    required this.maxDelay,
    required this.cqePeekCount,
    required this.cqeWaitCount,
    required this.cqeWaitTimeout,
    required this.memorySlabSize,
    required this.memoryPreallocationSize,
    required this.memoryQuotaSize,
  });

  InteractorConfiguration copyWith({
    int? staticBuffersCapacity,
    int? staticBufferSize,
    int? ringSize,
    int? ringFlags,
    Duration? timeoutCheckerPeriod,
    double? delayRandomizationFactor,
    Duration? baseDelay,
    Duration? maxDelay,
    int? cqePeekCount,
    int? cqeWaitCount,
    Duration? cqeWaitTimeout,
    int? memorySlabSize,
    int? memoryPreallocationSize,
    int? memoryQuotaSize,
  }) =>
      InteractorConfiguration(
        staticBuffersCapacity: staticBuffersCapacity ?? this.staticBuffersCapacity,
        staticBufferSize: staticBufferSize ?? this.staticBufferSize,
        ringSize: ringSize ?? this.ringSize,
        ringFlags: ringFlags ?? this.ringFlags,
        delayRandomizationFactor: delayRandomizationFactor ?? this.delayRandomizationFactor,
        baseDelay: baseDelay ?? this.baseDelay,
        maxDelay: maxDelay ?? this.maxDelay,
        cqePeekCount: cqePeekCount ?? this.cqePeekCount,
        cqeWaitCount: cqeWaitCount ?? this.cqeWaitCount,
        cqeWaitTimeout: cqeWaitTimeout ?? this.cqeWaitTimeout,
        memorySlabSize: memorySlabSize ?? this.memorySlabSize,
        memoryPreallocationSize: memoryPreallocationSize ?? this.memoryPreallocationSize,
        memoryQuotaSize: memoryQuotaSize ?? this.memoryQuotaSize,
      );
}
