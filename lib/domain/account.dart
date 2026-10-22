/// Ways to sign in besides staying a guest.
enum SignInMethod {
  apple('Apple', 'apple.com'),
  google('Google', 'google.com'),

  /// An email address and password, once the address is confirmed (the
  /// link in the email Firebase sends). Firebase calls it `password`.
  email('email', 'password');

  const SignInMethod(this.label, this.providerId);

  final String label;

  /// Firebase's provider ID for it.
  final String providerId;

  static SignInMethod? fromProviderId(String id) => values.where((m) => m.providerId == id).firstOrNull;
}

/// Who is using Travary on this phone: a guest (an anonymous account,
/// kept until the app is deleted) or someone signed in with Apple, Google or
/// an email and password, whose trips follow them to any phone.
class Account {
  const Account({required this.uid, this.methods = const {}, this.name, this.email, this.unconfirmedEmail});

  final String uid;

  /// How they can sign in; empty for a guest.
  final Set<SignInMethod> methods;
  final String? name;
  final String? email;

  /// An email and password waiting for the address to be confirmed. Until
  /// its link is opened it isn't a way in: the account is still a guest.
  final String? unconfirmedEmail;

  bool get isGuest => methods.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.uid == uid &&
      other.name == name &&
      other.email == email &&
      other.unconfirmedEmail == unconfirmedEmail &&
      other.methods.length == methods.length &&
      other.methods.containsAll(methods);

  @override
  int get hashCode => Object.hash(uid, name, email, unconfirmedEmail, Object.hashAllUnordered(methods));
}
