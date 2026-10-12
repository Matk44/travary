/// Ways to sign in besides staying a guest.
enum SignInMethod {
  apple('Apple', 'apple.com'),
  google('Google', 'google.com'),

  /// A link emailed to them (passwordless). Firebase calls it `password`.
  email('email', 'password');

  const SignInMethod(this.label, this.providerId);

  final String label;

  /// Firebase's provider ID for it.
  final String providerId;

  static SignInMethod? fromProviderId(String id) => values.where((m) => m.providerId == id).firstOrNull;
}

/// Who is using Travary on this phone: a guest (an anonymous account,
/// kept until the app is deleted) or someone signed in with Apple, Google or
/// an email link, whose trips follow them to any phone.
class Account {
  const Account({required this.uid, this.methods = const {}, this.name, this.email});

  final String uid;

  /// How they can sign in; empty for a guest.
  final Set<SignInMethod> methods;
  final String? name;
  final String? email;

  bool get isGuest => methods.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.uid == uid &&
      other.name == name &&
      other.email == email &&
      other.methods.length == methods.length &&
      other.methods.containsAll(methods);

  @override
  int get hashCode => Object.hash(uid, name, email, Object.hashAllUnordered(methods));
}
