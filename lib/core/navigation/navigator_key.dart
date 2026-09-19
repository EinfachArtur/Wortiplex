import 'package:flutter/widgets.dart';

/// Key of the app's root navigator. Lets code that outlives a single screen
/// (e.g. a callback fired when a full-screen ad closes) open a dialog on top
/// of whatever screen is visible then.
final rootNavigatorKey = GlobalKey<NavigatorState>();
