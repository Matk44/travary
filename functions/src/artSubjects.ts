/**
 * Picture subjects per booking kind: what a card's artwork should show.
 * Keep in step with lib/logic/art_subjects.dart (a Flutter test compares
 * the two lists). "generic" is always allowed as well.
 */
export const ART_SUBJECTS: Record<string, readonly string[]> = {
  flight: ['plane'],
  stay: ['chalet', 'camping', 'cottage', 'villa', 'resort', 'hotel'],
  attraction: ['waterpark', 'aquarium', 'zoo', 'museum', 'gardens', 'landmark', 'rollercoaster', 'castle'],
  dining: ['castle', 'breakfast', 'dessert', 'pizza', 'asian', 'burger', 'seafood', 'grill', 'bistro', 'bar', 'fine'],
  transport: ['train', 'ferry', 'bike', 'bus', 'taxi', 'car'],
  activity: ['snorkel', 'safari', 'space', 'spa', 'boat', 'hiking', 'citytour', 'class'],
  event: ['fireworks', 'festival', 'sport', 'concert', 'show'],
  note: [],
};

/** "flight: plane; stay: chalet, camping, …" for the prompt. */
export function describeArtSubjects(): string {
  return Object.entries(ART_SUBJECTS)
    .filter(([, subjects]) => subjects.length > 0)
    .map(([kind, subjects]) => `${kind}: ${subjects.join(', ')}`)
    .join('; ');
}

export function isArtSubject(kind: string, subject: unknown): subject is string {
  return typeof subject === 'string' && (subject === 'generic' || (ART_SUBJECTS[kind] ?? []).includes(subject));
}
