class AppConstants {
  static const String appName = 'Boodschappenlijstje';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String householdsCollection = 'households';
  static const String shoppingListsCollection = 'shoppingLists';
  static const String shoppingItemsCollection = 'shoppingItems';
  static const String templatesCollection = 'templates';

  // Units
  static const List<String> units = [
    'stuks',
    'kg',
    'gram',
    'liter',
    'ml',
    'pakken',
    'dozen',
    'blikken',
    'fles',
    'zakjes',
    'bosjes',
    'plakken',
  ];

  // Categories
  static const List<String> categories = [
    'Zuivel',
    'Groente & Fruit',
    'Vlees & Vis',
    'Brood & Bakkerij',
    'Dranken',
    'Diepvries',
    'Snacks & Snoep',
    'Huishouden',
    'Overig',
  ];

  // SharedPreferences keys
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefOfflineItems = 'offline_items';

  // Invite code length
  static const int inviteCodeLength = 6;
}
