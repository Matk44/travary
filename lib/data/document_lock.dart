import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// How asking to open the travel documents went.
enum UnlockResult {
  /// Face ID, fingerprint or the phone's passcode said yes.
  unlocked,

  /// The traveller backed out, or it didn't recognise them.
  refused,

  /// The phone has no passcode, so it can't lock anything: the documents
  /// open, and the screen suggests setting one.
  noLock,
}

/// The lock in front of the travel documents.
abstract class DocumentLock {
  Future<UnlockResult> unlock();
}

/// The phone's own lock: Face ID or a fingerprint, falling back to its
/// passcode.
class DeviceDocumentLock implements DocumentLock {
  DeviceDocumentLock([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<UnlockResult> unlock() async {
    try {
      if (!await _auth.isDeviceSupported()) return UnlockResult.noLock;
      // Not persisted across backgrounding: that re-opens the prompt every
      // time the app comes back and never answers until someone unlocks,
      // so a traveller without the passcode couldn't leave the screen. The
      // documents lock in the background anyway; leaving is a refusal.
      final ok = await _auth.authenticate(localizedReason: 'Unlock your travel documents');
      return ok ? UnlockResult.unlocked : UnlockResult.refused;
    } on LocalAuthException catch (e) {
      return e.code == LocalAuthExceptionCode.noCredentialsSet ? UnlockResult.noLock : UnlockResult.refused;
    } on PlatformException {
      return UnlockResult.refused;
    }
  }
}
