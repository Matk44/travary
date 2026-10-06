import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';

void main() {
  test('the public pages live on the support site', () {
    expect('${TravaryLinks.support}', 'https://matk44.github.io/travary_support/');
    expect('${TravaryLinks.privacy}', 'https://matk44.github.io/travary_support/privacy.html');
    expect('${TravaryLinks.terms}', 'https://matk44.github.io/travary_support/terms.html');
    expect('${TravaryLinks.deleteData}', 'https://matk44.github.io/travary_support/delete-account.html');
  });

  test('support email opens a new message with a subject', () {
    expect(TravaryLinks.supportEmail, 'dreamprayer.dev@gmail.com');
    expect('${TravaryLinks.email()}', 'mailto:dreamprayer.dev@gmail.com?subject=Travary%20support');
  });
}
