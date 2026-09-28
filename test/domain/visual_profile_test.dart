import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/app/build_info.dart';
import 'package:travary/domain/domain.dart';

void main() {
  final kyotoJson = <String, Object?>{
    'schemaVersion': 1,
    'primaryTheme': 'urban_heritage',
    'secondaryThemes': ['urban_modern'],
    'setting': 'urban',
    'moods': ['cultural', 'active'],
    'location': {
      'countryCode': 'JP',
      'countryName': 'Japan',
      'region': 'Kansai',
      'regionSlug': 'kansai',
      'city': 'Kyoto',
      'citySlug': 'kyoto',
      'locationQuery': 'Kyoto, Japan',
      'confidence': 0.91,
      'verificationStatus': 'verified',
      'placeId': 'google-place-id',
    },
    'confidence': 0.88,
    'sourceHash': 'a' * 64,
  };

  group('trips saved before visual profiles', () {
    Trip load(Map<String, Object?> json) => Trip.fromJson('t', {
      'title': 'Old trip',
      'ownerId': 'me',
      'memberIds': ['me'],
      ...json,
    });

    test('old trip JSON without a profile still loads', () {
      final trip = load({'theme': 'tropical'});
      expect(trip.visualProfile, isNull);
      expect(trip.theme, ExperienceTheme.coastalResort);
      expect(trip.title, 'Old trip');
    });

    test('legacy theme names map to the new looks', () {
      expect(load({'theme': 'classic'}).theme, ExperienceTheme.classicTravel);
      expect(load({'theme': 'tropical'}).theme, ExperienceTheme.coastalResort);
      expect(load({'theme': 'city'}).theme, ExperienceTheme.urbanModern);
      expect(load({'theme': 'snow'}).theme, ExperienceTheme.alpine);
      expect(load({'theme': 'countryside'}).theme, ExperienceTheme.countryside);
      expect(load({'theme': 'themepark'}).theme, ExperienceTheme.themepark);
    });

    test('without themeSource, classic (or none) is automatic and anything else manual', () {
      expect(load({}).themeSource, ThemeSource.auto);
      expect(load({'theme': 'classic'}).themeSource, ThemeSource.auto);
      expect(load({'theme': 'classic_travel'}).themeSource, ThemeSource.auto);
      expect(load({'theme': 'snow'}).themeSource, ThemeSource.manual);
      expect(load({'theme': 'urban_heritage'}).themeSource, ThemeSource.manual);
    });

    test('saving a later edit writes the new wire name', () {
      final trip = load({'theme': 'snow'});
      expect(trip.toEditableJson()['theme'], 'alpine');
      expect(trip.toEditableJson()['themeSource'], 'manual');
    });
  });

  group('profiles', () {
    test('new profile JSON round-trips', () {
      final profile = TripVisualProfile.tryParse(kyotoJson)!;
      expect(profile.primaryTheme, ExperienceTheme.urbanHeritage);
      expect(profile.secondaryThemes, [ExperienceTheme.urbanModern]);
      expect(profile.setting, TripSetting.urban);
      expect(profile.moods, [TripMood.cultural, TripMood.active]);
      expect(profile.location!.verification, LocationVerification.verified);
      expect(profile.location!.citySlug, 'kyoto');
      expect(profile.toJson(), kyotoJson);
      expect(TripVisualProfile.tryParse(profile.toJson()), profile);

      final trip = Trip.fromJson('t', {
        'title': 'Kyoto',
        'theme': 'urban_heritage',
        'themeSource': 'auto',
        'visualProfile': kyotoJson,
      });
      expect(trip.visualProfile, profile);
      expect(trip.effectiveTheme, ExperienceTheme.urbanHeritage);
    });

    test('unknown future values fall back safely', () {
      final profile = TripVisualProfile.tryParse({
        ...kyotoJson,
        'schemaVersion': 7,
        'primaryTheme': 'desert_oasis',
        'secondaryThemes': ['lunar_base', 'alpine', 'alpine'],
        'setting': 'orbit',
        'moods': ['zen', 'romantic'],
        'location': {
          'countryCode': 'XK',
          'city': 'Kyōto',
          'confidence': 3,
          'verificationStatus': 'double_checked',
          'extra': {'nested': true},
        },
        'confidence': 'very',
        'evidence': ['kept on the server only'],
        'newField': 42,
      })!;
      expect(profile.schemaVersion, 7);
      expect(profile.primaryTheme, ExperienceTheme.classicTravel);
      expect(profile.secondaryThemes, [ExperienceTheme.alpine]);
      expect(profile.setting, TripSetting.unknown);
      expect(profile.moods, [TripMood.romantic]);
      expect(profile.location!.countryCode, isNull, reason: 'not an ISO code');
      expect(profile.location!.citySlug, isNull, reason: 'no ASCII slug without the server\'s');
      expect(profile.location!.confidence, 1);
      expect(profile.location!.verification, LocationVerification.unverified);
      expect(profile.confidence, 0);
    });

    test('garbage is no profile at all', () {
      expect(TripVisualProfile.tryParse(null), isNull);
      expect(TripVisualProfile.tryParse('urban'), isNull);
      expect(TripVisualProfile.tryParse({'primaryTheme': 'alpine'}), isNull, reason: 'no source hash');
      final trip = Trip.fromJson('t', {'visualProfile': 'oops', 'theme': 42, 'themeSource': 'robot'});
      expect(trip.visualProfile, isNull);
      expect(trip.theme, ExperienceTheme.classicTravel);
      expect(trip.themeSource, ThemeSource.manual, reason: 'a non-classic stored value');
    });

    test('an ASCII place name gets a slug even from an older server', () {
      final hint = TripLocationHint.tryParse({'city': 'New York', 'region': 'New York', 'confidence': 0.9})!;
      expect(hint.citySlug, 'new_york');
      expect(asciiSlug('  New-York City '), 'new_york_city');
      expect(asciiSlug('São Paulo'), isNull, reason: 'the server folds accents; the fallback never guesses');
      expect(isSlug('kyoto'), isTrue);
      expect(isSlug('Kyoto'), isFalse);
    });
  });

  group('automatic and manual looks', () {
    final profile = TripVisualProfile.tryParse(kyotoJson)!;
    Trip trip({ThemeSource source = ThemeSource.auto, ExperienceTheme theme = ExperienceTheme.classicTravel}) => Trip(
      id: 't',
      title: 'Kyoto',
      theme: theme,
      themeSource: source,
      visualProfile: profile,
      ownerId: 'me',
      memberIds: const ['me'],
      createdAt: DateTime(2027),
      updatedAt: DateTime(2027),
    );

    test('an automatic trip shows its profile\'s look; a manual one the pick', () {
      expect(trip().effectiveTheme, ExperienceTheme.urbanHeritage);
      expect(trip(source: ThemeSource.manual, theme: ExperienceTheme.alpine).effectiveTheme, ExperienceTheme.alpine);
      expect(
        Trip(
          id: 't',
          title: 'x',
          ownerId: 'me',
          memberIds: const ['me'],
          createdAt: DateTime(2027),
          updatedAt: DateTime(2027),
        ).effectiveTheme,
        ExperienceTheme.classicTravel,
        reason: 'automatic without a profile yet',
      );
    });

    test('manual looks serialize their theme; automatic ones leave it to the classifier', () {
      final manual = trip(source: ThemeSource.manual, theme: ExperienceTheme.alpine).toEditableJson();
      expect(manual['theme'], 'alpine');
      expect(manual['themeSource'], 'manual');

      final automatic = trip().toEditableJson();
      expect(automatic.containsKey('theme'), isFalse);
      expect(automatic['themeSource'], 'auto');

      expect(trip().toJson()['theme'], 'classic_travel', reason: 'a new trip still has a theme');
      expect(trip().toJson()['themeSource'], 'auto');
    });

    test('the app never sends the visual profile', () {
      expect(trip().toJson().containsKey('visualProfile'), isFalse);
      expect(trip().toEditableJson().containsKey('visualProfile'), isFalse);
    });

    test('switching looks with copyWith', () {
      final picked = trip().copyWith(theme: ExperienceTheme.cruise, themeSource: ThemeSource.manual);
      expect(picked.effectiveTheme, ExperienceTheme.cruise);
      expect(picked.visualProfile, profile, reason: 'the profile stays');
      final back = picked.copyWith(themeSource: ThemeSource.auto);
      expect(back.effectiveTheme, ExperienceTheme.urbanHeritage);
    });

    test('a theme from a newer app is written back unchanged unless a look is picked', () {
      final newer = Trip.fromJson('t', {'theme': 'desert_oasis', 'themeSource': 'manual'});
      expect(newer.theme, ExperienceTheme.classicTravel);
      expect(newer.toEditableJson()['theme'], 'desert_oasis');
      expect(newer.copyWith(title: 'Renamed').toEditableJson()['theme'], 'desert_oasis');
      expect(newer.copyWith(theme: ExperienceTheme.alpine).toEditableJson()['theme'], 'alpine');
      expect(Trip.fromJson('t', {'theme': 'Not A Theme!'}).unknownTheme, isNull, reason: 'junk isn\'t kept');
    });
  });

  group('shared vocabulary', () {
    final ts = File('functions/src/visualVocabulary.ts').readAsStringSync();
    List<String> tsList(String name) {
      final body = RegExp('export const $name = \\[([^\\]]*)\\]').firstMatch(ts)!.group(1)!;
      return RegExp(r"'([a-z_]+)'").allMatches(body).map((m) => m.group(1)!).toList();
    }

    test('themes, settings, moods and statuses match the server', () {
      expect([for (final t in ExperienceTheme.values) t.wireName], tsList('EXPERIENCE_THEMES'));
      expect([for (final s in TripSetting.values) s.wireName], tsList('SETTINGS'));
      expect([for (final m in TripMood.values) m.wireName], tsList('MOODS'));
      expect([for (final v in LocationVerification.values) v.wireName], tsList('VERIFICATION_STATUSES'));
    });

    test('legacy aliases match the server', () {
      final body = RegExp(r'LEGACY_THEME_ALIASES[^{]*\{([^}]*)\}').firstMatch(ts)!.group(1)!;
      final server = {for (final m in RegExp(r"(\w+): '([a-z_]+)'").allMatches(body)) m.group(1)!: m.group(2)!};
      expect({for (final e in ExperienceTheme.legacyAliases.entries) e.key: e.value.wireName}, server);
    });

    test('the ISO country list matches the server', () {
      final block = ts.substring(ts.indexOf('ISO_COUNTRY_CODES'), ts.indexOf(".split(' ')"));
      final server = RegExp(r'\b[A-Z]{2}\b').allMatches(block).map((m) => m.group(0)!).toSet();
      expect(isoCountryCodes, server);
      expect(isoCountryCodes, hasLength(249));
    });

    test('the build number matches pubspec.yaml', () {
      final version = RegExp(
        r'^version: .*\+(\d+)$',
        multiLine: true,
      ).firstMatch(File('pubspec.yaml').readAsStringSync())!;
      expect(appBuildNumber, int.parse(version.group(1)!));
    });
  });
}
