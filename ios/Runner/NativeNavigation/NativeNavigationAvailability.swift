import Foundation

/// Bepaalt of de native Liquid Glass-navigatiebalk op dit toestel getoond mag
/// worden. Uitsluitend publieke `#available`-detectie -- geen private API's,
/// geen handmatig versienummers parsen.
///
/// Alles wat hiervan gebruikmaakt MOET bij `false` stilzwijgend niets doen,
/// zodat Flutter altijd op zijn eigen navbar terugvalt.
enum NativeNavigationAvailability {
    static var isSupported: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
}
