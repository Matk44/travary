import '../domain/trip.dart';

/// A scenic stage behind Travi. [floor] is where the scenery meets the cream
/// floor, in stage widths from its top, so a stage drawn at any width can be
/// lined up with Travi's floor. [props]: a folio and tickets are painted on
/// its floor, so the shared folio layer stays off it.
class OnboardingStage {
  const OnboardingStage(this.asset, {this.floor = 1.41, this.props = false});
  final String asset;
  final double floor;
  final bool props;
}

/// Onboarding's one camera: a 9:16 frame across the screen's width (the
/// approved storyboard's), with the stage's floor meeting its scenery
/// [floor] frame widths down. Every pose is drawn in this frame.
abstract final class OnboardingCamera {
  static const aspect = 9 / 16;

  /// Where the scenery meets the floor, in frame widths from the top.
  static const floor = 1.214;

  /// The key frames' canvas, in pixels (`docs/mockups/onboarding-keyframes-v1/`):
  /// what lettering on Travi's props is measured in.
  static const canvasWidth = 941.0;
  static const canvasHeight = 1672.0;
}

/// The paper workshop Travi rolls into before there's a destination; the
/// chosen place folds up over it.
const onboardingWorkshopStage = OnboardingStage('assets/onboarding/stages/workshop.webp', floor: 1215 / 787);

/// Somewhere lovely but nowhere in particular: every place without its own
/// stage, and the sign-in and pass desk when there's no holiday yet.
const onboardingAnywhereStage = 'assets/onboarding/stages/anywhere.webp';

const _anywhere = OnboardingStage(onboardingAnywhereStage);
const _bali = OnboardingStage('assets/onboarding/bali-stage-prop-free-v1.png');
const _kyoto = OnboardingStage('assets/onboarding/stages/city_jp_kyoto.webp');

/// Approved city stages by `COUNTRY/city_slug`. A city's own stage wins over
/// its country's.
const onboardingCityStages = <String, String>{
  'AE/dubai': 'assets/onboarding/stages/city_ae_dubai.webp',
  'AU/melbourne': 'assets/onboarding/stages/city_au_melbourne.webp',
  'AU/sydney': 'assets/onboarding/stages/city_au_sydney.webp',
  'CA/vancouver': 'assets/onboarding/stages/city_ca_vancouver.webp',
  'CZ/prague': 'assets/onboarding/stages/city_cz_prague.webp',
  'ES/barcelona': 'assets/onboarding/stages/city_es_barcelona.webp',
  'ES/madrid': 'assets/onboarding/stages/city_es_madrid.webp',
  'FR/paris': 'assets/onboarding/stages/city_fr_paris.webp',
  'GB/edinburgh': 'assets/onboarding/stages/city_gb_edinburgh.webp',
  'GB/london': 'assets/onboarding/stages/city_gb_london.webp',
  'GR/athens': 'assets/onboarding/stages/city_gr_athens.webp',
  'IT/florence': 'assets/onboarding/stages/city_it_florence.webp',
  'IT/rome': 'assets/onboarding/stages/city_it_rome.webp',
  'IT/venice': 'assets/onboarding/stages/city_it_venice.webp',
  'JP/osaka': 'assets/onboarding/stages/city_jp_osaka.webp',
  'JP/tokyo': 'assets/onboarding/stages/city_jp_tokyo.webp',
  'KR/seoul': 'assets/onboarding/stages/city_kr_seoul.webp',
  'MX/cancun': 'assets/onboarding/stages/city_mx_cancun.webp',
  'MY/kuala_lumpur': 'assets/onboarding/stages/city_my_kuala_lumpur.webp',
  'NL/amsterdam': 'assets/onboarding/stages/city_nl_amsterdam.webp',
  'NZ/queenstown': 'assets/onboarding/stages/city_nz_queenstown.webp',
  'PT/lisbon': 'assets/onboarding/stages/city_pt_lisbon.webp',
  'TH/bangkok': 'assets/onboarding/stages/city_th_bangkok.webp',
  'TR/istanbul': 'assets/onboarding/stages/city_tr_istanbul.webp',
  'US/new_york': 'assets/onboarding/stages/city_us_new_york.webp',
  'US/orlando': 'assets/onboarding/stages/city_us_orlando.webp',
  'US/san_francisco': 'assets/onboarding/stages/city_us_san_francisco.webp',
  'ZA/cape_town': 'assets/onboarding/stages/city_za_cape_town.webp',
};

/// Country stages by ISO code; cities and regions inherit them. Hong Kong
/// and Singapore are city-states, so their city art is the country.
const onboardingCountryStages = <String, String>{
  'AE': 'assets/onboarding/stages/country_ae.webp',
  'AU': 'assets/onboarding/stages/country_au.webp',
  'BR': 'assets/onboarding/stages/country_br.webp',
  'CA': 'assets/onboarding/stages/country_ca.webp',
  'CH': 'assets/onboarding/stages/country_ch.webp',
  'CN': 'assets/onboarding/stages/country_cn.webp',
  'DE': 'assets/onboarding/stages/country_de.webp',
  'ES': 'assets/onboarding/stages/country_es.webp',
  'FR': 'assets/onboarding/stages/country_fr.webp',
  'GB': 'assets/onboarding/stages/country_gb.webp',
  'GR': 'assets/onboarding/stages/country_gr.webp',
  'HK': 'assets/onboarding/stages/city_hk_hong_kong.webp',
  'ID': 'assets/onboarding/stages/country_id.webp',
  'IN': 'assets/onboarding/stages/country_in.webp',
  'IT': 'assets/onboarding/stages/country_it.webp',
  'JP': 'assets/onboarding/stages/country_jp.webp',
  'KR': 'assets/onboarding/stages/country_kr.webp',
  'MX': 'assets/onboarding/stages/country_mx.webp',
  'NL': 'assets/onboarding/stages/country_nl.webp',
  'NZ': 'assets/onboarding/stages/country_nz.webp',
  'PT': 'assets/onboarding/stages/country_pt.webp',
  'SG': 'assets/onboarding/stages/city_sg_singapore.webp',
  'TH': 'assets/onboarding/stages/country_th.webp',
  'TR': 'assets/onboarding/stages/country_tr.webp',
  'US': 'assets/onboarding/stages/country_us.webp',
  'ZA': 'assets/onboarding/stages/country_za.webp',
};

/// Countries with a city stage but no country stage yet: their city stands
/// in, so choosing "Czechia" still shows it. A country stage takes over.
const onboardingCountryCities = <String, String>{'CZ': 'prague', 'MY': 'kuala_lumpur'};

/// The stage for [destination]: the city's own, then the selected Bali and
/// Kyoto scenes, then the country's, then a stand-in city
/// ([onboardingCountryCities]), then Anywhere. Never Bali for the rest of
/// Indonesia or Kyoto for the rest of Japan: they have country stages.
OnboardingStage onboardingStage(
  TripDestination? destination, {
  Map<String, String> cities = onboardingCityStages,
  Map<String, String> countries = onboardingCountryStages,
  Map<String, String> standIns = onboardingCountryCities,
}) {
  if (destination == null) return _anywhere;
  final code = destination.countryCode;
  final city = destination.citySlug == null ? null : cities['$code/${destination.citySlug}'];
  if (city != null) return OnboardingStage(city);
  if (code == 'ID' && destination.regionSlug == 'bali') return _bali;
  if (code == 'JP' && destination.citySlug == 'kyoto') return _kyoto;
  final country = countries[code];
  if (country != null) return OnboardingStage(country);
  final standIn = standIns[code] == null ? null : cities['$code/${standIns[code]}'];
  return standIn == null ? _anywhere : OnboardingStage(standIn);
}

/// The stage's picture for [destination] (see [onboardingStage]).
String onboardingStageFor(
  TripDestination? destination, {
  Map<String, String> cities = onboardingCityStages,
  Map<String, String> countries = onboardingCountryStages,
}) => onboardingStage(destination, cities: cities, countries: countries).asset;
