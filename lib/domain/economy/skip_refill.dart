class SkipState {
  final int available;
  final DateTime? refillStartedAt; // null means "at max, no timer running"
  const SkipState({required this.available, required this.refillStartedAt});
}

/// Computes how many "skip round" charges have regenerated since the timer
/// started, given a max allowance and a fixed interval per charge.
class SkipRefillCalculator {
  final int maxAllowance;
  final Duration refillInterval;

  const SkipRefillCalculator({required this.maxAllowance, required this.refillInterval});

  SkipState refill(SkipState current, {DateTime? now}) {
    if (current.available >= maxAllowance || current.refillStartedAt == null) {
      return current;
    }
    final n = now ?? DateTime.now();
    final elapsed = n.difference(current.refillStartedAt!);
    final chargesGained = elapsed.inMilliseconds ~/ refillInterval.inMilliseconds;
    if (chargesGained <= 0) return current;

    final newAvailable = (current.available + chargesGained).clamp(0, maxAllowance);
    if (newAvailable >= maxAllowance) {
      return SkipState(available: maxAllowance, refillStartedAt: null);
    }
    final consumedMillis = chargesGained * refillInterval.inMilliseconds;
    final newRefillStart = current.refillStartedAt!.add(Duration(milliseconds: consumedMillis));
    return SkipState(available: newAvailable, refillStartedAt: newRefillStart);
  }

  /// Call after a skip is spent: starts the regeneration timer if it wasn't
  /// already running.
  SkipState consume(SkipState current, {DateTime? now}) {
    if (current.available <= 0) return current;
    final refillStartedAt = current.refillStartedAt ?? (now ?? DateTime.now());
    return SkipState(available: current.available - 1, refillStartedAt: refillStartedAt);
  }
}
