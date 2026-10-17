import 'package:flutter_test/flutter_test.dart';
import 'package:travary/logic/countdown_widget_setup.dart';

void main() {
  const android = (supported: true, added: false, canPin: true);
  const androidByHand = (supported: true, added: false, canPin: false);
  const ios = (supported: true, added: false, canPin: false);
  const placed = (supported: true, added: true, canPin: false);

  group('who is offered the widget', () {
    bool offers(HomeWidgetStatus status, {bool everAdded = false, bool declined = false}) =>
        offersCountdownWidget(status: status, everAdded: everAdded, declined: declined);

    test('a phone that can have it, and hasn\'t, is offered it', () {
      expect(offers(ios), isTrue);
      expect(offers(android), isTrue);
    });

    test('not where there is no widget (iOS 15 and 16)', () {
      expect(offers(homeWidgetUnavailable), isFalse);
    });

    test('not once it is on the home screen', () {
      expect(offers(placed), isFalse);
    });

    test('not to someone who has had it and taken it off: they know it exists', () {
      expect(offers(ios, everAdded: true), isFalse);
    });

    test('not after "Not now"', () {
      expect(offers(ios, declined: true), isFalse);
    });
  });

  group('the sheet', () {
    CountdownWidgetWords words(HomeWidgetPlatform platform, HomeWidgetStatus status) =>
        countdownWidgetWords(platform: platform, status: status);

    test('Android with a launcher that can place it: one button does it, no steps', () {
      final w = words(HomeWidgetPlatform.android, android);
      expect(w.action, countdownWidgetPinAction);
      expect(w.steps, isEmpty);
    });

    test('iOS can\'t be asked, so it shows the steps and a "Got it"', () {
      final w = words(HomeWidgetPlatform.ios, ios);
      expect(w.steps, countdownWidgetSteps(HomeWidgetPlatform.ios));
      expect(w.steps, hasLength(3));
      expect(w.action, 'Got it');
    });

    test('an Android launcher that can\'t place it gets Android\'s steps', () {
      final w = words(HomeWidgetPlatform.android, androidByHand);
      expect(w.steps, countdownWidgetSteps(HomeWidgetPlatform.android));
      expect(w.action, 'Got it');
    });

    test('each platform words the steps its own way', () {
      final ios = countdownWidgetSteps(HomeWidgetPlatform.ios).join(' ');
      final android = countdownWidgetSteps(HomeWidgetPlatform.android).join(' ');
      expect(ios, contains('Add Widget'));
      expect(android, contains('Widgets'));
      expect(android, isNot(contains('Add Widget')));
    });

    test('once it is on the home screen the sheet says so and has nothing left to do', () {
      for (final platform in HomeWidgetPlatform.values) {
        final w = words(platform, placed);
        expect(w.title, 'It’s on your home screen');
        expect(w.steps, isEmpty);
        expect(w.action, 'Done');
      }
    });

    test('says Free, never a plan or a price', () {
      final w = words(HomeWidgetPlatform.ios, ios);
      expect(w.lead, contains('Free'));
      expect('${w.title} ${w.lead}', isNot(contains('Annual Pass')));
      expect('${w.title} ${w.lead}', isNot(contains('Holiday Pass')));
    });
  });

  test('Profile\'s row says where the widget stands', () {
    expect(countdownWidgetSettingSubtitle(placed), 'On your home screen');
    expect(countdownWidgetSettingSubtitle(ios), contains('home screen'));
  });
}
