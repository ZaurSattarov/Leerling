import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Security-hardening (2026-09-24): versleutelde opslag van de Supabase-sessie.
///
/// De standaard `SharedPreferencesLocalStorage` van supabase_flutter bewaart de
/// volledige sessie (access- én refresh-JWT) **plaintext** in de app-sandbox.
/// Op een geroot/gejailbreakt toestel of via een device-backup is dat leesbaar.
/// Deze implementatie vervangt die opslag door OS-versleutelde opslag:
/// - Android: Keystore-backed EncryptedSharedPreferences (AES-GCM);
/// - iOS/macOS: Keychain.
///
/// Toegankelijkheid `first_unlock`: de sessie blijft leesbaar zodra het toestel
/// ná een herstart één keer is ontgrendeld. De Leerling-app heeft (nog) geen
/// achtergrond-isolate dat de sessie op vergrendeld scherm nodig heeft, maar
/// `first_unlock` blijft veilig én consistent met de Instrecteur-app.
///
/// Sleutel [kSupabaseSecureSessionKey] is BEWUST verschillend van Instrecteur
/// (`klantio-instructeur-...`) — de apps hebben aparte sandboxes/bundle-IDs,
/// dus er is geen technische reden voor dezelfde key, en verschillende keys
/// voorkomen dat een test-fixture per ongeluk de andere app raakt.

/// Sleutel waaronder de Supabase-sessie versleuteld wordt opgeslagen.
const String kSupabaseSecureSessionKey =
    'klantio-leerling-supabase-session';

/// Minimale sleutel/waarde-opslag zodat [SecureSupabaseLocalStorage] getest
/// kan worden zonder platformkanalen.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);
}

/// [SecureKeyValueStore] bovenop `flutter_secure_storage` met de juiste
/// Keystore-/Keychain-opties.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore([
    // Android gebruikt standaard al Keystore-backed encryptie (AES-GCM); de
    // oude `encryptedSharedPreferences`-flag is deprecated en overbodig.
    // iOS/macOS: `first_unlock` (consistent met Instrecteur).
    this._storage = const FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}

/// [LocalStorage]-implementatie die de Supabase-sessie versleuteld opslaat.
class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage({
    SecureKeyValueStore? store,
    this.persistSessionKey = kSupabaseSecureSessionKey,
  }) : _store = store ?? const FlutterSecureKeyValueStore();

  final SecureKeyValueStore _store;
  final String persistSessionKey;

  @override
  Future<void> initialize() async {
    // Geen initialisatie nodig: Keystore/Keychain zijn direct beschikbaar.
  }

  @override
  Future<bool> hasAccessToken() => _store.containsKey(persistSessionKey);

  @override
  Future<String?> accessToken() => _store.read(persistSessionKey);

  @override
  Future<void> removePersistedSession() => _store.delete(persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(persistSessionKey, persistSessionString);
}
