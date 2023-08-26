import 'package:retry/retry.dart';

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
      );
}

class InteractorUdpMulticastConfiguration {
  final String groupAddress;
  final String localAddress;
  final String? localInterface;
  final int? interfaceIndex;
  final bool calculateInterfaceIndex;

  InteractorUdpMulticastConfiguration._(
    this.groupAddress,
    this.localAddress,
    this.localInterface,
    this.interfaceIndex,
    this.calculateInterfaceIndex,
  );

  factory InteractorUdpMulticastConfiguration.byInterfaceIndex({
    required String groupAddress,
    required String localAddress,
    required int interfaceIndex,
  }) {
    return InteractorUdpMulticastConfiguration._(groupAddress, localAddress, null, interfaceIndex, false);
  }

  factory InteractorUdpMulticastConfiguration.byInterfaceName({
    required String groupAddress,
    required String localAddress,
    required String interfaceName,
  }) {
    return InteractorUdpMulticastConfiguration._(groupAddress, localAddress, interfaceName, -1, true);
  }
}

class InteractorUdpMulticastSourceConfiguration {
  final String groupAddress;
  final String localAddress;
  final String sourceAddress;

  InteractorUdpMulticastSourceConfiguration({
    required this.groupAddress,
    required this.localAddress,
    required this.sourceAddress,
  });
}

class InteractorUdpMulticastManager {
  void Function(InteractorUdpMulticastConfiguration configuration) _onAddMembership = (configuration) => {};
  void Function(InteractorUdpMulticastConfiguration configuration) _onDropMembership = (configuration) => {};
  void Function(InteractorUdpMulticastSourceConfiguration configuration) _onAddSourceMembership = (configuration) => {};
  void Function(InteractorUdpMulticastSourceConfiguration configuration) _onDropSourceMembership = (configuration) => {};

  void subscribe(
      {required void Function(InteractorUdpMulticastConfiguration configuration) onAddMembership,
      required void Function(InteractorUdpMulticastConfiguration configuration) onDropMembership,
      required void Function(InteractorUdpMulticastSourceConfiguration configuration) onAddSourceMembership,
      required void Function(InteractorUdpMulticastSourceConfiguration configuration) onDropSourceMembership}) {
    _onAddMembership = onAddMembership;
    _onDropMembership = onDropMembership;
    _onAddSourceMembership = onAddSourceMembership;
    _onDropSourceMembership = onDropSourceMembership;
  }

  void addMembership(InteractorUdpMulticastConfiguration configuration) => _onAddMembership(configuration);

  void dropMembership(InteractorUdpMulticastConfiguration configuration) => _onDropMembership(configuration);

  void addSourceMembership(InteractorUdpMulticastSourceConfiguration configuration) => _onAddSourceMembership(configuration);

  void dropSourceMembership(InteractorUdpMulticastSourceConfiguration configuration) => _onDropSourceMembership(configuration);
}

class InteractorRetryConfiguration {
  final Duration baseDelay;
  final double randomizationFactor;
  final Duration maxDelay;
  final int maxAttempts;
  final bool Function(Exception exception) predicate;

  late final RetryOptions options;

  InteractorRetryConfiguration({
    required this.baseDelay,
    required this.randomizationFactor,
    required this.maxDelay,
    required this.maxAttempts,
    required this.predicate,
  }) {
    options = RetryOptions(
      delayFactor: baseDelay,
      randomizationFactor: randomizationFactor,
      maxDelay: maxDelay,
      maxAttempts: maxAttempts,
    );
  }

  InteractorRetryConfiguration copyWith({
    Duration? baseDelay,
    double? randomizationFactor,
    Duration? maxDelay,
    int? maxAttempts,
    bool Function(Exception exception)? predicate,
    void Function(Exception exception)? onRetry,
  }) =>
      InteractorRetryConfiguration(
        baseDelay: baseDelay ?? this.baseDelay,
        randomizationFactor: randomizationFactor ?? this.randomizationFactor,
        maxDelay: maxDelay ?? this.maxDelay,
        maxAttempts: maxAttempts ?? this.maxAttempts,
        predicate: predicate ?? this.predicate,
      );
}
