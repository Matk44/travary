/// Travary's public pages: support, privacy, terms and deleting your data,
/// on travary.app (`website/content/legal/`). The App Store and Google Play
/// listings and Google's sign-in branding link to the same pages.
abstract final class TravaryLinks {
  static const _site = 'https://travary.app/';

  static final support = Uri.parse('${_site}support');
  static final privacy = Uri.parse('${_site}privacy');
  static final terms = Uri.parse('${_site}terms');
  static final deleteData = Uri.parse('${_site}delete-account');

  /// Where the Annual Pass is managed or cancelled: the subscriptions page
  /// of the store it's bought from.
  static final appStoreSubscriptions = Uri.parse('https://apps.apple.com/account/subscriptions');
  static final playSubscriptions = Uri.parse(
    'https://play.google.com/store/account/subscriptions?sku=travary_annual_pass&package=com.travary.app',
  );

  static const supportEmail = 'dreamprayer.dev@gmail.com';

  /// A new email to support, with [subject].
  static Uri email({String subject = 'Travary support'}) =>
      Uri(scheme: 'mailto', path: supportEmail, query: 'subject=${Uri.encodeComponent(subject)}');
}
