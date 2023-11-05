class InteractorWorkerConfiguration {
  final int buffersCount;
  final int bufferSize;
  final int ringSize;
  final int ringFlags;
  final Duration timeoutCheckerPeriod;
  final double delayRandomizationFactor;
  final int cqePeekCount;
  final int cqeWaitCount;
  final Duration cqeWaitTimeout;
  final Duration baseDelay;
  final Duration maxDelay;
  final bool trace;
  final int memorySlabSize;
  final int memoryPreallocationSize;
  final int memoryQuotaSize;

  InteractorWorkerConfiguration({
    required this.buffersCount,
    required this.bufferSize,
    required this.ringSize,
    required this.ringFlags,
    required this.timeoutCheckerPeriod,
    required this.delayRandomizationFactor,
    required this.baseDelay,
    required this.maxDelay,
    required this.cqePeekCount,
    required this.cqeWaitCount,
    required this.cqeWaitTimeout,
    required this.trace,
    required this.memorySlabSize,
    required this.memoryPreallocationSize,
    required this.memoryQuotaSize,
  });

  InteractorWorkerConfiguration copyWith({
    int? buffersCount,
    int? bufferSize,
    int? ringSize,
    int? ringFlags,
    Duration? timeoutCheckerPeriod,
    double? delayRandomizationFactor,
    Duration? baseDelay,
    Duration? maxDelay,
    int? cqePeekCount,
    int? cqeWaitCount,
    Duration? cqeWaitTimeout,
    bool? trace,
    int? memorySlabSize,
    int? memoryPreallocationSize,
    int? memoryQuotaSize,
  }) =>
      InteractorWorkerConfiguration(
        buffersCount: buffersCount ?? this.buffersCount,
        bufferSize: bufferSize ?? this.bufferSize,
        ringSize: ringSize ?? this.ringSize,
        ringFlags: ringFlags ?? this.ringFlags,
        timeoutCheckerPeriod: timeoutCheckerPeriod ?? this.timeoutCheckerPeriod,
        delayRandomizationFactor: delayRandomizationFactor ?? this.delayRandomizationFactor,
        baseDelay: baseDelay ?? this.baseDelay,
        maxDelay: maxDelay ?? this.maxDelay,
        cqePeekCount: cqePeekCount ?? this.cqePeekCount,
        cqeWaitCount: cqeWaitCount ?? this.cqeWaitCount,
        cqeWaitTimeout: cqeWaitTimeout ?? this.cqeWaitTimeout,
        trace: trace ?? this.trace,
        memorySlabSize: memorySlabSize ?? this.memorySlabSize,
        memoryPreallocationSize: memoryPreallocationSize ?? this.memoryPreallocationSize,
        memoryQuotaSize: memoryQuotaSize ?? this.memoryQuotaSize,
      );
}
