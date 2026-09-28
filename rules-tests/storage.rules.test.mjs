// Storage rules: art packs are read-only for signed-in travellers; ticket
// attachments stay members-only. Run with `npm --prefix rules-tests test`.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { deleteObject, getBytes, getMetadata, ref, updateMetadata, uploadBytes } from 'firebase/storage';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-travary',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
    storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearStorage();
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (admin) => {
    await uploadBytes(ref(admin.storage(), 'art-packs/catalog.json'), new TextEncoder().encode('{"schemaVersion":1}'));
    await uploadBytes(ref(admin.storage(), 'art-packs/city_jp_kyoto/3/pack.zip'), new Uint8Array([0x50, 0x4b, 5, 6]));
    await setDoc(doc(admin.firestore(), 'trips/t1'), { title: 'Kyoto', ownerId: 'alice', memberIds: ['alice'] });
    await uploadBytes(ref(admin.storage(), 'trips/t1/attachments/ticket.pdf'), new Uint8Array([37, 80, 68, 70]), {
      contentType: 'application/pdf',
    });
  });
});

const signedIn = (uid = 'alice') => env.authenticatedContext(uid).storage();
const anonymous = () => env.unauthenticatedContext().storage();
const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

// ------------------------------------------------------------------ art packs

test('signed-in travellers can read the catalog and pack archives', async () => {
  await assertSucceeds(getBytes(ref(signedIn('stranger'), 'art-packs/catalog.json')));
  await assertSucceeds(getMetadata(ref(signedIn('stranger'), 'art-packs/catalog.json')));
  await assertSucceeds(getBytes(ref(signedIn(), 'art-packs/city_jp_kyoto/3/pack.zip')));
});

test('signed-out users can\'t read art packs', async () => {
  await assertFails(getBytes(ref(anonymous(), 'art-packs/catalog.json')));
  await assertFails(getBytes(ref(anonymous(), 'art-packs/city_jp_kyoto/3/pack.zip')));
});

test('the app can\'t create, update or delete art packs', async () => {
  const storage = signedIn();
  await assertFails(uploadBytes(ref(storage, 'art-packs/catalog.json'), new TextEncoder().encode('{}')));
  await assertFails(uploadBytes(ref(storage, 'art-packs/evil/1/pack.zip'), new Uint8Array([1, 2, 3])));
  await assertFails(uploadBytes(ref(storage, 'art-packs/new.png'), png, { contentType: 'image/png' }));
  await assertFails(updateMetadata(ref(storage, 'art-packs/catalog.json'), { contentType: 'text/plain' }));
  await assertFails(deleteObject(ref(storage, 'art-packs/city_jp_kyoto/3/pack.zip')));
  await assertFails(uploadBytes(ref(anonymous(), 'art-packs/catalog.json'), new Uint8Array([1])));
  await assertFails(deleteObject(ref(anonymous(), 'art-packs/catalog.json')));
});

// ---------------------------------------------------- ticket attachments (unchanged)

test('members can read, add and delete their trip\'s tickets', async () => {
  const storage = signedIn('alice');
  await assertSucceeds(getBytes(ref(storage, 'trips/t1/attachments/ticket.pdf')));
  await assertSucceeds(uploadBytes(ref(storage, 'trips/t1/attachments/photo.png'), png, { contentType: 'image/png' }));
  await assertSucceeds(deleteObject(ref(storage, 'trips/t1/attachments/ticket.pdf')));
});

test('non-members and signed-out users can\'t touch a trip\'s tickets', async () => {
  for (const storage of [signedIn('mallory'), anonymous()]) {
    await assertFails(getBytes(ref(storage, 'trips/t1/attachments/ticket.pdf')));
    await assertFails(uploadBytes(ref(storage, 'trips/t1/attachments/x.png'), png, { contentType: 'image/png' }));
    await assertFails(deleteObject(ref(storage, 'trips/t1/attachments/ticket.pdf')));
  }
});

test('tickets must be images or PDFs under 20 MB', async () => {
  const storage = signedIn('alice');
  await assertFails(uploadBytes(ref(storage, 'trips/t1/attachments/notes.txt'), new Uint8Array([104, 105]), {
    contentType: 'text/plain',
  }));
  await assertFails(uploadBytes(ref(storage, 'trips/t1/attachments/huge.pdf'), new Uint8Array(20 * 1024 * 1024), {
    contentType: 'application/pdf',
  }));
  await assertSucceeds(uploadBytes(ref(storage, 'trips/t1/attachments/ok.pdf'), new Uint8Array(1024), {
    contentType: 'application/pdf',
  }));
});
