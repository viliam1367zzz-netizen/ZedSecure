class CountryDetector {
  static final Map<String, String> _countryMappings = {
    'austria': 'AT', 'at': 'AT', 'wien': 'AT', 'vienna': 'AT',
    'australia': 'AU', 'au': 'AU', 'sydney': 'AU', 'melbourne': 'AU',
    'azerbaijan': 'AZ', 'az': 'AZ', 'baku': 'AZ',
    'belgium': 'BE', 'be': 'BE', 'brussels': 'BE',
    'canada': 'CA', 'ca': 'CA', 'toronto': 'CA', 'vancouver': 'CA', 'montreal': 'CA',
    'switzerland': 'CH', 'ch': 'CH', 'zurich': 'CH', 'geneva': 'CH',
    'czech': 'CZ', 'cz': 'CZ', 'prague': 'CZ',
    'germany': 'DE', 'de': 'DE', 'berlin': 'DE', 'frankfurt': 'DE', 'munich': 'DE',
    'denmark': 'DK', 'dk': 'DK', 'copenhagen': 'DK',
    'estonia': 'EE', 'ee': 'EE', 'tallinn': 'EE',
    'spain': 'ES', 'es': 'ES', 'madrid': 'ES', 'barcelona': 'ES',
    'finland': 'FI', 'fi': 'FI', 'helsinki': 'FI',
    'france': 'FR', 'fr': 'FR', 'paris': 'FR',
    'uk': 'GB', 'gb': 'GB', 'united kingdom': 'GB', 'england': 'GB', 'london': 'GB',
    'croatia': 'HR', 'hr': 'HR', 'zagreb': 'HR',
    'hungary': 'HU', 'hu': 'HU', 'budapest': 'HU',
    'india': 'IN', 'in': 'IN', 'mumbai': 'IN', 'delhi': 'IN', 'bangalore': 'IN',
    'iran': 'IR', 'ir': 'IR', 'tehran': 'IR',
    'italy': 'IT', 'it': 'IT', 'rome': 'IT', 'milan': 'IT',
    'japan': 'JP', 'jp': 'JP', 'tokyo': 'JP', 'osaka': 'JP',
    'latvia': 'LV', 'lv': 'LV', 'riga': 'LV',
    'netherlands': 'NL', 'nl': 'NL', 'holland': 'NL', 'amsterdam': 'NL',
    'norway': 'NO', 'no': 'NO', 'oslo': 'NO',
    'poland': 'PL', 'pl': 'PL', 'warsaw': 'PL',
    'portugal': 'PT', 'pt': 'PT', 'lisbon': 'PT',
    'romania': 'RO', 'ro': 'RO', 'bucharest': 'RO',
    'serbia': 'RS', 'rs': 'RS', 'belgrade': 'RS',
    'sweden': 'SE', 'se': 'SE', 'stockholm': 'SE',
    'singapore': 'SG', 'sg': 'SG',
    'slovakia': 'SK', 'sk': 'SK', 'bratislava': 'SK',
    'turkey': 'TR', 'tr': 'TR', 'istanbul': 'TR', 'ankara': 'TR',
    'usa': 'US', 'us': 'US', 'united states': 'US', 'america': 'US',
    'new york': 'US', 'los angeles': 'US', 'chicago': 'US', 'dallas': 'US',
    'seattle': 'US', 'miami': 'US', 'san francisco': 'US', 'washington': 'US',
    'brazil': 'BR', 'br': 'BR', 'sao paulo': 'BR',
    'mexico': 'MX', 'mx': 'MX', 'mexico city': 'MX',
    'argentina': 'AR', 'ar': 'AR', 'buenos aires': 'AR',
    'hong kong': 'HK', 'hk': 'HK', 'hongkong': 'HK',
    'korea': 'KR', 'kr': 'KR', 'south korea': 'KR', 'seoul': 'KR',
    'taiwan': 'TW', 'tw': 'TW', 'taipei': 'TW',
    'thailand': 'TH', 'th': 'TH', 'bangkok': 'TH',
    'vietnam': 'VN', 'vn': 'VN', 'hanoi': 'VN', 'ho chi minh': 'VN',
    'philippines': 'PH', 'ph': 'PH', 'manila': 'PH',
    'indonesia': 'ID', 'id': 'ID', 'jakarta': 'ID',
    'malaysia': 'MY', 'my': 'MY', 'kuala lumpur': 'MY',
    'uae': 'AE', 'ae': 'AE', 'dubai': 'AE', 'abu dhabi': 'AE',
    'israel': 'IL', 'il': 'IL', 'tel aviv': 'IL',
    'new zealand': 'NZ', 'nz': 'NZ', 'auckland': 'NZ',
    'south africa': 'ZA', 'za': 'ZA', 'johannesburg': 'ZA',
    'russia': 'RU', 'ru': 'RU', 'moscow': 'RU',
    'china': 'CN', 'cn': 'CN', 'beijing': 'CN', 'shanghai': 'CN',
    'cloudflare': 'US', 'cf': 'US', 'worker': 'US',
  };

  static final Map<String, String> _countryNames = {
    'AT': 'Austria', 'AU': 'Australia', 'AZ': 'Azerbaijan',
    'BE': 'Belgium', 'BR': 'Brazil', 'CA': 'Canada',
    'CH': 'Switzerland', 'CN': 'China', 'CZ': 'Czech Republic',
    'DE': 'Germany', 'DK': 'Denmark', 'EE': 'Estonia',
    'ES': 'Spain', 'FI': 'Finland', 'FR': 'France',
    'GB': 'United Kingdom', 'HK': 'Hong Kong', 'HR': 'Croatia',
    'HU': 'Hungary', 'ID': 'Indonesia', 'IL': 'Israel',
    'IN': 'India', 'IR': 'Iran', 'IT': 'Italy',
    'JP': 'Japan', 'KR': 'South Korea', 'LV': 'Latvia',
    'MX': 'Mexico', 'MY': 'Malaysia', 'NL': 'Netherlands',
    'NO': 'Norway', 'NZ': 'New Zealand', 'PH': 'Philippines',
    'PL': 'Poland', 'PT': 'Portugal', 'RO': 'Romania',
    'RS': 'Serbia', 'RU': 'Russia', 'SE': 'Sweden',
    'SG': 'Singapore', 'SK': 'Slovakia', 'TH': 'Thailand',
    'TR': 'Turkey', 'TW': 'Taiwan', 'US': 'United States',
    'VN': 'Vietnam', 'ZA': 'South Africa', 'AE': 'UAE',
    'AR': 'Argentina', 'XX': 'Unknown',
  };

  static String detectCountryCode(String remark, String address) {
    final searchText = '${remark.toLowerCase()} ${address.toLowerCase()}';
    
    final bracketRegex = RegExp(r'[\[\(]([A-Z]{2})[\]\)]', caseSensitive: false);
    final bracketMatch = bracketRegex.firstMatch(remark.toUpperCase());
    if (bracketMatch != null) {
      final code = bracketMatch.group(1);
      if (code != null && _countryNames.containsKey(code)) {
        return code;
      }
    }
    
    final flagRegex = RegExp(r'[\uD83C][\uDDE6-\uDDFF][\uD83C][\uDDE6-\uDDFF]');
    final flagMatch = flagRegex.firstMatch(remark);
    if (flagMatch != null) {
      final flag = flagMatch.group(0)!;
      final first = flag.codeUnitAt(1) - 0xDDE6 + 65;
      final second = flag.codeUnitAt(3) - 0xDDE6 + 65;
      final code = String.fromCharCodes([first, second]);
      if (_countryNames.containsKey(code)) {
        return code;
      }
    }
    
    for (var entry in _countryMappings.entries) {
      if (searchText.contains(entry.key)) {
        return entry.value;
      }
    }
    
    final words = remark.toUpperCase().split(RegExp(r'[\s\-_|]'));
    for (var word in words) {
      if (word.length == 2 && _countryNames.containsKey(word)) {
        return word;
      }
    }
    
    return 'XX';
  }

  static String getCountryName(String countryCode) {
    return _countryNames[countryCode.toUpperCase()] ?? 'Unknown';
  }
}
