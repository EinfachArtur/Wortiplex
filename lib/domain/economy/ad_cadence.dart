/// Decides after which finished rounds a full-screen ad may be shown.
///
/// With `everyNRounds: 1` an ad follows every round, with 3 only every third.
class AdCadence {
  final int everyNRounds;
  int _roundsSinceLastAd = 0;

  AdCadence({required this.everyNRounds}) : assert(everyNRounds >= 1);

  /// Call once per finished round. Returns true if an ad is due now.
  bool onRoundCompleted() {
    _roundsSinceLastAd++;
    if (_roundsSinceLastAd >= everyNRounds) {
      _roundsSinceLastAd = 0;
      return true;
    }
    return false;
  }
}
