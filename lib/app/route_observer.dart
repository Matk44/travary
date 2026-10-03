import 'package:flutter/widgets.dart';

/// Tells screens when a full screen pushed over them closes (sheets and
/// dialogs don't count), so Today can replay its countdown entry.
final appRouteObserver = RouteObserver<PageRoute<dynamic>>();
