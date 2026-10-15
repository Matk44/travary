/// Whether Smart Import and automatic trip looks may send anything to
/// Google's Gemini AI. Apple asks apps to say clearly what goes to a
/// third-party AI and to get explicit permission first (guideline
/// 5.1.2(i)), so nothing goes until the traveller says yes. One answer, on
/// this phone, covers both uses (`logic/ai_consent.dart`).
enum AiConsent {
  /// Never asked, or the question was put away without an answer.
  undecided,

  /// "Allow": Smart Import reads files, and trips get automatic looks.
  allowed,

  /// "Not now": nothing is sent. Smart Import still asks when it's used;
  /// a trip's page doesn't offer automatic looks again.
  declined;

  /// The stored name, or [undecided] for anything else (asked again).
  static AiConsent parse(Object? name) => values.firstWhere((value) => value.name == name, orElse: () => undecided);
}
