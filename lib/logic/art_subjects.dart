import '../domain/domain.dart';

/// What a booking's picture should show: a subject word per booking kind
/// ("pizza", "castle", "train"). Artwork files carry the same word in their
/// name, so the right picture is found for each booking.
///
/// Keep in step with `functions/src/artSubjects.ts` (Smart Import asks
/// Gemini to choose from the same list); a test checks they match.
///
/// Each subject has keywords that pick it from a booking's name, place and
/// details. Order matters: the first subject with a matching keyword wins,
/// so specific subjects come before broad ones.
const artSubjects = <BookingKind, Map<String, List<String>>>{
  BookingKind.flight: {
    'plane': ['flight', 'airline', 'airways', 'air'],
  },
  BookingKind.stay: {
    'chalet': ['chalet', 'ski', 'alpine', 'mountain lodge'],
    'camping': ['camp', 'campsite', 'camping', 'glamping', 'tent', 'caravan', 'rv park'],
    'cottage': ['cottage', 'farmhouse', 'barn', 'b&b', 'bed and breakfast', 'cabin'],
    'villa': ['villa', 'apartment', 'airbnb', 'condo', 'holiday home', 'house'],
    'resort': ['resort', 'beach', 'island', 'polynesian', 'tropical', 'lagoon'],
    'hotel': ['hotel', 'inn', 'suites', 'hostel', 'lodge'],
  },
  BookingKind.attraction: {
    'waterpark': ['water park', 'waterpark', 'splash', 'aqua', 'typhoon', 'slides'],
    'aquarium': ['aquarium', 'sea life', 'oceanarium'],
    'zoo': ['zoo', 'safari park', 'wildlife park', 'animal kingdom'],
    'museum': ['museum', 'gallery', 'exhibition', 'science centre', 'science center'],
    'gardens': ['garden', 'gardens', 'botanic', 'botanical', 'arboretum'],
    'landmark': ['tower', 'observation', 'summit', 'monument', 'cathedral', 'palace', 'bridge', 'eiffel'],
    'rollercoaster': ['rollercoaster', 'roller coaster', 'coaster', 'thrill', 'funfair', 'fun fair', 'studios'],
    'castle': ['castle', 'kingdom', 'magic', 'fairy', 'princess', 'theme park', 'disney'],
  },
  BookingKind.dining: {
    'castle': ['castle', 'royal', 'banquet', 'be our guest', 'princess', 'character'],
    'breakfast': ['breakfast', 'brunch', 'pancake', 'pancakes', 'cafe', 'café', 'coffee', 'bakery', 'donut'],
    'dessert': ['ice cream', 'gelato', 'dessert', 'cake', 'chocolate', 'creamery', 'sweet'],
    'pizza': ['pizza', 'pizzeria', 'trattoria', 'italian', 'pasta'],
    'asian': ['sushi', 'ramen', 'noodle', 'noodles', 'thai', 'chinese', 'japanese', 'dim sum', 'wok',
        'curry', 'indian', 'asian', 'korean', 'vietnamese', 'pho'],
    'burger': ['burger', 'burgers', 'diner', 'fries', 'hot dog'],
    'seafood': ['seafood', 'fish', 'oyster', 'lobster', 'crab', 'shrimp'],
    'grill': ['grill', 'steak', 'steakhouse', 'bbq', 'barbecue', 'smokehouse', 'churrasco', 'luau'],
    'bistro': ['bistro', 'brasserie', 'french', 'bistrot', 'tapas'],
    'bar': ['bar', 'pub', 'cocktail', 'cocktails', 'tavern', 'brewery', 'wine', 'lounge'],
    'fine': ['fine dining', 'tasting menu', 'michelin'],
  },
  BookingKind.transport: {
    'train': ['train', 'rail', 'railway', 'eurostar', 'express', 'metro', 'tram', 'amtrak', 'avanti'],
    'ferry': ['ferry', 'boat', 'crossing', 'sailing'],
    'bike': ['bike', 'bicycle', 'cycle', 'scooter'],
    'bus': ['bus', 'coach', 'shuttle'],
    'taxi': ['taxi', 'cab', 'uber', 'lyft', 'transfer', 'chauffeur'],
    'car': ['car', 'hire', 'rental', 'alamo', 'hertz', 'avis', 'enterprise', 'drive'],
  },
  BookingKind.activity: {
    'snorkel': ['snorkel', 'snorkelling', 'dive', 'diving', 'scuba', 'reef'],
    'safari': ['safari', 'wildlife', 'whale', 'dolphin', 'jeep'],
    'space': ['space', 'rocket', 'nasa', 'planetarium'],
    'spa': ['spa', 'massage', 'wellness', 'yoga'],
    'boat': ['boat', 'cruise', 'airboat', 'sail', 'kayak', 'canoe', 'catamaran', 'gondola'],
    'hiking': ['hike', 'hiking', 'trek', 'trail', 'walk', 'climb'],
    'citytour': ['city tour', 'walking tour', 'bus tour', 'sightseeing', 'food tour', 'segway'],
    'class': ['class', 'workshop', 'lesson', 'cooking', 'course'],
  },
  BookingKind.event: {
    'fireworks': ['firework', 'fireworks'],
    'festival': ['festival', 'carnival', 'parade', 'fair'],
    'sport': ['match', 'stadium', 'football', 'soccer', 'baseball', 'basketball', 'rugby', 'cricket',
        'tennis', 'grand prix', 'race'],
    'concert': ['concert', 'gig', 'orchestra', 'symphony', 'band', 'tour'],
    'show': ['show', 'theatre', 'theater', 'musical', 'circus', 'ballet', 'opera', 'comedy', 'cirque'],
  },
  BookingKind.note: {},
};

/// Every kind also accepts this: a picture that suits anything of its kind.
const genericSubject = 'generic';

bool isArtSubject(BookingKind kind, String? subject) =>
    subject != null && (subject == genericSubject || (artSubjects[kind]?.containsKey(subject) ?? false));

/// The subject for [booking]: the one Smart Import chose, else the first
/// whose keywords appear in the name, place or details. Null if none fits.
String? artSubjectFor(Booking booking) {
  if (isArtSubject(booking.kind, booking.artSubject)) return booking.artSubject;
  final haystack = [
    booking.title,
    booking.location,
    ...booking.details.values,
  ].whereType<String>().join(' ').toLowerCase();
  for (final entry in (artSubjects[booking.kind] ?? const <String, List<String>>{}).entries) {
    for (final keyword in entry.value) {
      if (_containsWord(haystack, keyword)) return entry.key;
    }
  }
  return null;
}

final _wordCache = <String, RegExp>{};

bool _containsWord(String haystack, String keyword) {
  final pattern = _wordCache.putIfAbsent(
    keyword,
    () => RegExp('(^|[^a-z0-9])${RegExp.escape(keyword)}(\$|[^a-z0-9])'),
  );
  return pattern.hasMatch(haystack);
}
