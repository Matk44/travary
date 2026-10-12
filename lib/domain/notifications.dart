/// Whether this phone lets Travary show notifications (flight alerts).
enum NotificationPermission {
  /// Allowed (provisionally on iOS counts too).
  allowed,

  /// Turned off, in the system's prompt or in Settings. (Android may let
  /// the app ask once more.)
  denied,

  /// Not asked yet. Android before 13 never needs asking.
  notAsked,
}
