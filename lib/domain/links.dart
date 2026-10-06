/// Travary's public pages: support, privacy, terms and deleting your data
/// (the `travary_support` repo, served by GitHub Pages). The App Store and
/// Google Play listings link to the same pages.
abstract final class TravaryLinks {
  static const _site = 'https://matk44.github.io/travary_support/';

  static final support = Uri.parse(_site);
  static final privacy = Uri.parse('${_site}privacy.html');
  static final terms = Uri.parse('${_site}terms.html');
  static final deleteData = Uri.parse('${_site}delete-account.html');

  static const supportEmail = 'dreamprayer.dev@gmail.com';

  /// A new email to support, with [subject].
  static Uri email({String subject = 'Travary support'}) =>
      Uri(scheme: 'mailto', path: supportEmail, query: 'subject=${Uri.encodeComponent(subject)}');
}
