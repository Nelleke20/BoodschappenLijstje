class CategoryHelper {
  static const Map<String, List<String>> _categoryKeywords = {
    'Zuivel': [
      'melk', 'kaas', 'yoghurt', 'boter', 'room', 'kwark', 'vla', 'karnemelk',
      'crème', 'brie', 'gouda', 'edam', 'cottage', 'mozzarella', 'ricotta',
    ],
    'Groente & Fruit': [
      'appel', 'peer', 'banaan', 'sinaasappel', 'citroen', 'druiven', 'aardbei',
      'tomaat', 'komkommer', 'sla', 'ui', 'knoflook', 'aardappel', 'wortel',
      'broccoli', 'bloemkool', 'spinazie', 'paprika', 'courgette', 'aubergine',
      'avocado', 'mango', 'ananas', 'kiwi', 'meloen', 'kers', 'pruim',
      'champignon', 'prei', 'selderij', 'radijs', 'biet', 'andijvie',
      'groente', 'fruit', 'vers',
    ],
    'Vlees & Vis': [
      'kip', 'gehakt', 'biefstuk', 'varkens', 'rund', 'lam', 'kalf',
      'worst', 'ham', 'spek', 'bacon', 'salami', 'rookvlees',
      'zalm', 'tonijn', 'garnalen', 'makreel', 'kabeljauw', 'tilapia',
      'haring', 'mosselen', 'kreeft', 'krab', 'vis', 'vlees',
      'hamburger', 'filet', 'schnit', 'tartaar',
    ],
    'Brood & Bakkerij': [
      'brood', 'croissant', 'beschuit', 'crackers', 'ciabatta', 'baguette',
      'pita', 'wrap', 'toast', 'muffin', 'cake', 'taart', 'koek', 'biscuit',
      'rogge', 'volkoren', 'stokbrood', 'bolletje', 'bagel',
    ],
    'Dranken': [
      'water', 'sap', 'frisdrank', 'cola', 'fanta', 'sprite', 'bier', 'wijn',
      'koffie', 'thee', 'melk', 'limonade', 'ijsthee', 'smoothie', 'energiedrink',
      'spa', 'chocomel', 'drinkyoghurt', 'drank', 'jenever', 'whisky', 'vodka',
    ],
    'Diepvries': [
      'diepvries', 'bevroren', 'ijsje', 'ijs', 'sorbet', 'friet', 'frites',
      'pizza diep', 'kipnuggets', 'garnalen diep',
    ],
    'Snacks & Snoep': [
      'chips', 'nootjes', 'chocolade', 'snoep', 'popcorn', 'drop', 'kauwgom',
      'koekjes', 'wafels', 'stroopwafel', 'pepernoten', 'M&M', 'twix', 'kitkat',
      'haribo', 'lolly', 'marshmallow', 'pretzels', 'crackers snack',
    ],
    'Huishouden': [
      'allesreiniger', 'wc-reiniger', 'afwasmiddel', 'wasmiddel', 'schuurspons',
      'vuilniszakken', 'toiletpapier', 'keukenpapier', 'schoonmaak', 'bleekwater',
      'ontstopper', 'airfreshener', 'vloeibare zeep', 'shampoo', 'conditioner',
      'tandpasta', 'scheergel', 'deodorant', 'wasverzachter', 'vloeistof',
      'schoonmaakdoekjes', 'handdoek', 'badkamer', 'poetsen',
    ],
  };

  static String detectCategory(String itemName) {
    final nameLower = itemName.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (nameLower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Overig';
  }
}
