enum SubscriptionTier { none, monthly, yearly }

class SubscriptionStatus {
  final SubscriptionTier tier;
  final String? productId;
  final DateTime? expiresAt;
  final bool autoRenewing;
  final bool adsRemovedLifetime; // one-time "remove ads" purchase, independent of subscription

  const SubscriptionStatus({
    this.tier = SubscriptionTier.none,
    this.productId,
    this.expiresAt,
    this.autoRenewing = false,
    this.adsRemovedLifetime = false,
  });

  bool get isActive =>
      tier != SubscriptionTier.none && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool get isAdFree => isActive || adsRemovedLifetime;

  SubscriptionStatus copyWith({
    SubscriptionTier? tier,
    String? productId,
    DateTime? expiresAt,
    bool? autoRenewing,
    bool? adsRemovedLifetime,
  }) {
    return SubscriptionStatus(
      tier: tier ?? this.tier,
      productId: productId ?? this.productId,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenewing: autoRenewing ?? this.autoRenewing,
      adsRemovedLifetime: adsRemovedLifetime ?? this.adsRemovedLifetime,
    );
  }

  Map<String, dynamic> toMap() => {
        'tier': tier.name,
        'productId': productId,
        'expiresAt': expiresAt?.toIso8601String(),
        'autoRenewing': autoRenewing,
        'adsRemovedLifetime': adsRemovedLifetime,
      };

  factory SubscriptionStatus.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const SubscriptionStatus();
    return SubscriptionStatus(
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => SubscriptionTier.none,
      ),
      productId: map['productId'] as String?,
      expiresAt: map['expiresAt'] != null ? DateTime.tryParse(map['expiresAt'] as String) : null,
      autoRenewing: map['autoRenewing'] as bool? ?? false,
      adsRemovedLifetime: map['adsRemovedLifetime'] as bool? ?? false,
    );
  }
}
