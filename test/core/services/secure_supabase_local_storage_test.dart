import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/services/secure_supabase_local_storage.dart';

/// In-memory [SecureKeyValueStore] zodat de LocalStorage-contractlaag getest
/// kan worden zonder Keystore/Keychain-platformkanalen.
class _FakeSecureStore implements SecureKeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  late _FakeSecureStore fake;
  late SecureSupabaseLocalStorage storage;

  setUp(() {
    fake = _FakeSecureStore();
    storage = SecureSupabaseLocalStorage(store: fake);
  });

  test('leeg bij start: geen persisted sessie', () async {
    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test('persistSession bewaart de sessie en is uitleesbaar', () async {
    const session = '{"access_token":"abc","refresh_token":"def"}';
    await storage.persistSession(session);

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), session);
  });

  test('persistSession overschrijft een bestaande sessie', () async {
    await storage.persistSession('eerste');
    await storage.persistSession('tweede');
    expect(await storage.accessToken(), 'tweede');
  });

  test('removePersistedSession wist de sessie (logout)', () async {
    await storage.persistSession('sessie');
    await storage.removePersistedSession();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test('gebruikt standaard kSupabaseSecureSessionKey (Leerling-specifiek)', () async {
    await storage.persistSession('sessie');
    expect(await fake.read(kSupabaseSecureSessionKey), 'sessie');
    // Voor de zekerheid: mag NIET de Instrecteur-sleutel raken.
    expect(kSupabaseSecureSessionKey.contains('leerling'), isTrue);
    expect(kSupabaseSecureSessionKey.contains('instructeur'), isFalse);
  });

  test('initialize is veilig aanroepbaar (no-op)', () async {
    await storage.initialize();
    expect(await storage.hasAccessToken(), isFalse);
  });
}
