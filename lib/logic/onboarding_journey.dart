/// The beats of onboarding, one stage throughout: what Travi is doing and
/// what the words say at each. Screens only lay these out.
enum OnboardingBeat {
  /// Travi rolls into the workshop; no destination yet.
  arrival,

  /// The destination has appeared: "When do we leave?"
  dates,

  /// "Got a booking for me?"
  booking,

  /// Smart Import reading the chosen screenshot or PDF.
  reading,

  /// It couldn't read it: try again, or type it in.
  misread,

  /// The first booking is saved and in Travi's hands.
  proof,

  /// "Keep your holiday with you": the optional sign-in.
  account,

  /// The email branch of the sign-in.
  email,

  /// Signed in: the tag goes into the folio.
  signedIn,

  /// "Shall I help with the rest?": the passes.
  desk,

  /// Off they go, into the holiday.
  sendoff,
}

/// A beat's words: the headline, its coral ending, and the line under it.
typedef OnboardingWords = ({String text, String accent, String? subtitle});

/// What the stage says at [beat]. [place]: the holiday's place ("Tokyo");
/// [problem]: why a booking couldn't be read; [day]: the saved booking's day
/// of the holiday.
OnboardingWords onboardingWordsFor(
  OnboardingBeat beat, {
  String? place,
  bool emailSent = false,
  bool covered = false,
  String? problem,
  int? day,
}) => switch (beat) {
  OnboardingBeat.arrival => (
    text: 'Where are\nwe ',
    accent: 'off to?',
    subtitle: 'Your bookings, days and tickets together.',
  ),
  OnboardingBeat.dates => (
    text: 'When do\nwe ',
    accent: 'leave?',
    subtitle: '${place ?? 'Your holiday'}, here we come.',
  ),
  OnboardingBeat.booking => (
    text: 'Got a booking\n',
    accent: 'for me?',
    subtitle: 'A screenshot or PDF is all I need.',
  ),
  OnboardingBeat.reading => (
    text: 'Reading\nyour ',
    accent: 'booking…',
    subtitle: 'Getting the details ready for you to check.',
  ),
  OnboardingBeat.misread => (text: 'Hmm, I couldn’t\n', accent: 'read that.', subtitle: problem),
  OnboardingBeat.proof when day != null => (text: 'Day $day,\n', accent: 'sorted.', subtitle: null),
  OnboardingBeat.proof => (text: 'That’s one\nbit ', accent: 'handled.', subtitle: null),
  OnboardingBeat.account => (
    text: 'Keep your\nholiday\n',
    accent: 'with you.',
    subtitle: 'Sign in to find your plan on another phone.',
  ),
  OnboardingBeat.email when emailSent => (
    text: 'Check your\n',
    accent: 'inbox.',
    subtitle: 'One tap on the link and you’re in.',
  ),
  OnboardingBeat.email => (
    text: 'One little link.\n',
    accent: 'And you’re in.',
    subtitle: 'Enter your email to sign in.',
  ),
  OnboardingBeat.signedIn => (text: 'Your holiday.\n', accent: 'Linked to you.', subtitle: null),
  OnboardingBeat.desk when covered => (
    text: 'Your holiday.\n',
    accent: 'Ready to go.',
    subtitle: 'This holiday already has Plus.',
  ),
  OnboardingBeat.desk => (text: 'Shall I help\n', accent: 'with the rest?', subtitle: 'Less typing. More holiday.'),
  OnboardingBeat.sendoff => (text: '${place ?? 'Your holiday'},\n', accent: 'here we come!', subtitle: null),
};
