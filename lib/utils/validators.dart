class Validators {
  static String? required(String? value, [String fieldName = 'Dit veld']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is verplicht';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mailadres is verplicht';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Voer een geldig e-mailadres in';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wachtwoord is verplicht';
    }
    if (value.length < 6) {
      return 'Wachtwoord moet minimaal 6 tekens zijn';
    }
    return null;
  }

  static String? inviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Uitnodigingscode is verplicht';
    }
    if (value.trim().length != 6) {
      return 'Uitnodigingscode moet 6 tekens zijn';
    }
    return null;
  }
}
