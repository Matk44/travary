import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';

void main() {
  test('the public pages live on travary.app', () {
    expect('${TravaryLinks.support}', 'https://travary.app/support');
    expect('${TravaryLinks.privacy}', 'https://travary.app/privacy');
    expect('${TravaryLinks.terms}', 'https://travary.app/terms');
    expect('${TravaryLinks.deleteData}', 'https://travary.app/delete-account');
  });

  test('the Annual Pass is managed in the store it was bought from', () {
    expect('${TravaryLinks.appStoreSubscriptions}', 'https://apps.apple.com/account/subscriptions');
    expect(TravaryLinks.playSubscriptions.queryParameters, {
      'sku': 'travary_annual_pass',
      'package': 'com.travary.app',
    });
  });

  test('support email opens a new message with a subject', () {
    expect(TravaryLinks.supportEmail, 'dreamprayer.dev@gmail.com');
    expect('${TravaryLinks.email()}', 'mailto:dreamprayer.dev@gmail.com?subject=Travary%20support');
  });
}
