import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

class TrackingService {
  const TrackingService();

  /// Requests App Tracking Transparency (ATT) authorization on iOS if not yet determined.
  /// Safe to call on Android or any platform (returns status or no-op).
  Future<TrackingStatus> requestTrackingAuthorization() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final currentStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (currentStatus == TrackingStatus.notDetermined) {
          // A short delay helps ensure the native iOS view hierarchy is ready to present the dialog
          await Future.delayed(const Duration(milliseconds: 250));
          return await AppTrackingTransparency.requestTrackingAuthorization();
        }
        return currentStatus;
      }
      return TrackingStatus.notSupported;
    } catch (e) {
      debugPrint('TrackingService.requestTrackingAuthorization error: $e');
      return TrackingStatus.notSupported;
    }
  }

  /// Gets the current ATT authorization status.
  Future<TrackingStatus> getTrackingStatus() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await AppTrackingTransparency.trackingAuthorizationStatus;
      }
      return TrackingStatus.notSupported;
    } catch (e) {
      debugPrint('TrackingService.getTrackingStatus error: $e');
      return TrackingStatus.notSupported;
    }
  }
}
