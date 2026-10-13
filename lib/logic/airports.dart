import 'destinations.dart';

/// Airports as the places they serve, by code and by the names people
/// call them: a flight into Kansai (KIX) goes to Osaka, one into Narita to
/// Tokyo. Read only at the ends of flights and transfers, where a code
/// means an airport (a hotel called "SEA VIEW" isn't Seattle).

/// The place the airport in [text] serves ("Kansai International (KIX)"
/// is Osaka), or null when it names no airport the app knows.
Place? airportPlace(String text) {
  for (final match in _code.allMatches(text)) {
    if (airportCodes[match[0]] case final name?) return placeNamed(name);
  }
  final folded = ' ${foldPlaceText(text)} ';
  for (final MapEntry(key: airport, value: name) in _airportNames.entries) {
    if (folded.contains(' $airport ')) return placeNamed(name);
  }
  return null;
}

/// Three capitals on their own: "(KIX)", "LHR T5".
final _code = RegExp(r'(?<![A-Za-z])[A-Z]{3}(?![A-Za-z])');

/// IATA codes and the place each airport serves, by its name in the
/// built-in list (`destinations.dart`; a test checks every one is there).
const airportCodes = {
  // Japan and East Asia.
  'HND': 'Tokyo', 'NRT': 'Tokyo', 'KIX': 'Osaka', 'ITM': 'Osaka', 'CTS': 'Hokkaido', 'OKA': 'Okinawa', //
  'HIJ': 'Hiroshima', 'ICN': 'Seoul', 'GMP': 'Seoul', 'PUS': 'Busan', 'CJU': 'Jeju', 'PEK': 'Beijing', //
  'PKX': 'Beijing', 'PVG': 'Shanghai', 'SHA': 'Shanghai', 'TPE': 'Taipei', 'TSA': 'Taipei', 'HKG': 'Hong Kong',
  // South-east Asia and India.
  'SIN': 'Singapore', 'BKK': 'Bangkok', 'DMK': 'Bangkok', 'HKT': 'Phuket', 'CNX': 'Chiang Mai', //
  'USM': 'Koh Samui', 'KBV': 'Krabi', 'DPS': 'Bali', 'LOP': 'Lombok', 'CGK': 'Jakarta', 'KUL': 'Kuala Lumpur',
  'LGK': 'Langkawi', 'PEN': 'Penang', 'HAN': 'Hanoi', 'SGN': 'Ho Chi Minh City', 'REP': 'Siem Reap', //
  'SAI': 'Siem Reap', 'PPS': 'Palawan', 'MPH': 'Boracay', 'DEL': 'Delhi', 'BOM': 'Mumbai', 'GOI': 'Goa', //
  'GOX': 'Goa', 'COK': 'Kerala', 'TRV': 'Kerala', 'JAI': 'Rajasthan', 'KTM': 'Kathmandu',
  // Britain and Ireland.
  'LHR': 'London', 'LGW': 'London', 'STN': 'London', 'LTN': 'London', 'LCY': 'London', 'SEN': 'London', //
  'EDI': 'Edinburgh', 'GLA': 'Glasgow', 'MAN': 'Manchester', 'LPL': 'Liverpool', 'BRS': 'Bristol', //
  'CWL': 'Cardiff', 'BFS': 'Belfast', 'BHD': 'Belfast', 'NQY': 'Cornwall', 'EXT': 'Devon', 'DUB': 'Dublin',
  // France, Italy, Spain, Portugal.
  'CDG': 'Paris', 'ORY': 'Paris', 'BVA': 'Paris', 'NCE': 'Nice', 'BOD': 'Bordeaux', 'LYS': 'Lyon', //
  'MRS': 'Marseille', 'AJA': 'Corsica', 'BIA': 'Corsica', 'FCO': 'Rome', 'CIA': 'Rome', 'FLR': 'Florence', //
  'PSA': 'Tuscany', 'VCE': 'Venice', 'TSF': 'Venice', 'VRN': 'Verona', 'MXP': 'Milan', 'LIN': 'Milan', //
  'BGY': 'Milan', 'NAP': 'Naples', 'CTA': 'Sicily', 'PMO': 'Sicily', 'OLB': 'Sardinia', 'CAG': 'Sardinia', //
  'BRI': 'Puglia', 'BCN': 'Barcelona', 'MAD': 'Madrid', 'SVQ': 'Seville', 'AGP': 'Málaga', 'GRX': 'Granada',
  'VLC': 'Valencia', 'ALC': 'Benidorm', 'PMI': 'Mallorca', 'MAH': 'Menorca', 'IBZ': 'Ibiza', 'TFS': 'Tenerife',
  'TFN': 'Tenerife', 'ACE': 'Lanzarote', 'LPA': 'Gran Canaria', 'FUE': 'Fuerteventura', 'GRO': 'Costa Brava',
  'LIS': 'Lisbon', 'OPO': 'Porto', 'FAO': 'Algarve', 'FNC': 'Madeira', 'PDL': 'Azores',
  // The rest of Europe.
  'ATH': 'Athens', 'JTR': 'Santorini', 'JMK': 'Mykonos', 'HER': 'Crete', 'CHQ': 'Crete', 'CFU': 'Corfu', //
  'RHO': 'Rhodes', 'ZTH': 'Zakynthos', 'EFL': 'Kefalonia', 'DBV': 'Dubrovnik', 'SPU': 'Split', //
  'IST': 'Istanbul', 'SAW': 'Istanbul', 'AYT': 'Antalya', 'BJV': 'Bodrum', 'DLM': 'Dalaman', //
  'NAV': 'Cappadocia', 'ASR': 'Cappadocia', 'PFO': 'Paphos', 'AMS': 'Amsterdam', 'BRU': 'Brussels', //
  'CRL': 'Brussels', 'BER': 'Berlin', 'MUC': 'Munich', 'HAM': 'Hamburg', 'VIE': 'Vienna', 'SZG': 'Salzburg',
  'INN': 'Tyrol', 'ZRH': 'Zurich', 'GVA': 'Geneva', 'PRG': 'Prague', 'BUD': 'Budapest', 'KRK': 'Kraków', //
  'WAW': 'Warsaw', 'WMI': 'Warsaw', 'CPH': 'Copenhagen', 'ARN': 'Stockholm', 'BMA': 'Stockholm', //
  'OSL': 'Oslo', 'HEL': 'Helsinki', 'RVN': 'Lapland', 'KEF': 'Reykjavik', 'RKV': 'Reykjavik',
  // North America.
  'MCO': 'Orlando', 'SFB': 'Orlando', 'MIA': 'Miami', 'EYW': 'Florida Keys', 'JFK': 'New York', //
  'LGA': 'New York', 'EWR': 'New York', 'LAS': 'Las Vegas', 'LAX': 'Los Angeles', 'SFO': 'San Francisco', //
  'SAN': 'San Diego', 'SNA': 'Anaheim', 'HNL': 'Hawaii', 'OGG': 'Maui', 'ORD': 'Chicago', 'MDW': 'Chicago', //
  'BOS': 'Boston', 'IAD': 'Washington DC', 'DCA': 'Washington DC', 'MSY': 'New Orleans', 'BNA': 'Nashville',
  'SEA': 'Seattle', 'ANC': 'Alaska', 'PHX': 'Arizona', 'SLC': 'Utah', 'DEN': 'Colorado', 'ABQ': 'New Mexico',
  'AUS': 'Texas', 'DFW': 'Texas', 'IAH': 'Texas', 'HOU': 'Texas', 'YYZ': 'Toronto', 'YVR': 'Vancouver', //
  'YUL': 'Montreal', 'YQB': 'Quebec City', 'CUN': 'Cancún', 'MEX': 'Mexico City', 'SJD': 'Los Cabos', //
  'PUJ': 'Punta Cana', 'HAV': 'Havana',
  // South America, Oceania, the Middle East and Africa.
  'GIG': 'Rio de Janeiro', 'SDU': 'Rio de Janeiro', 'GRU': 'São Paulo', 'CGH': 'São Paulo', //
  'EZE': 'Buenos Aires', 'AEP': 'Buenos Aires', 'CUZ': 'Cusco', 'SYD': 'Sydney', 'MEL': 'Melbourne', //
  'BNE': 'Brisbane', 'OOL': 'Gold Coast', 'CNS': 'Cairns', 'PER': 'Perth', 'AYQ': 'Uluru', 'AKL': 'Auckland',
  'ZQN': 'Queenstown', 'WLG': 'Wellington', 'ROT': 'Rotorua', 'DXB': 'Dubai', 'DWC': 'Dubai', //
  'AUH': 'Abu Dhabi', 'DOH': 'Doha', 'TLV': 'Tel Aviv', 'CAI': 'Cairo', 'SSH': 'Sharm El Sheikh', //
  'HRG': 'Hurghada', 'LXR': 'Luxor', 'RAK': 'Marrakech', 'CPT': 'Cape Town', 'JNB': 'Johannesburg', //
  'ZNZ': 'Zanzibar',
};

/// Airports' own names, folded, and the place each serves, for airports
/// whose name doesn't say the city ("Narita", "Schiphol").
const _airportNames = {
  'heathrow': 'London', 'gatwick': 'London', 'stansted': 'London', 'luton': 'London', //
  'narita': 'Tokyo', 'haneda': 'Tokyo', 'kansai': 'Osaka', 'itami': 'Osaka', 'chitose': 'Hokkaido', //
  'incheon': 'Seoul', 'gimpo': 'Seoul', 'suvarnabhumi': 'Bangkok', 'don mueang': 'Bangkok', //
  'changi': 'Singapore', 'ngurah rai': 'Bali', 'charles de gaulle': 'Paris', 'orly': 'Paris', //
  'schiphol': 'Amsterdam', 'zaventem': 'Brussels', 'fiumicino': 'Rome', 'ciampino': 'Rome', //
  'malpensa': 'Milan', 'linate': 'Milan', 'marco polo': 'Venice', 'capodichino': 'Naples', //
  'barajas': 'Madrid', 'el prat': 'Barcelona', 'humberto delgado': 'Lisbon', 'eleftherios venizelos': 'Athens',
  'sabiha gokcen': 'Istanbul', 'schwechat': 'Vienna', 'kastrup': 'Copenhagen', 'arlanda': 'Stockholm', //
  'gardermoen': 'Oslo', 'vantaa': 'Helsinki', 'keflavik': 'Reykjavik', 'newark': 'New York', //
  'la guardia': 'New York', 'laguardia': 'New York', 'o hare': 'Chicago', 'dulles': 'Washington DC', //
  'sea tac': 'Seattle', 'seatac': 'Seattle', 'harry reid': 'Las Vegas', 'mccarran': 'Las Vegas', //
  'louis armstrong': 'New Orleans', 'tullamarine': 'Melbourne', 'kingsford smith': 'Sydney', //
  'galeao': 'Rio de Janeiro', 'guarulhos': 'São Paulo', 'ezeiza': 'Buenos Aires', 'ben gurion': 'Tel Aviv',
  'hamad': 'Doha', 'menara': 'Marrakech', 'or tambo': 'Johannesburg',
};
