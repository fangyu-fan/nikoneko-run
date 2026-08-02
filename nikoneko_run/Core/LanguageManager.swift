import Foundation

final class LanguageBundle: Bundle, @unchecked Sendable {
    nonisolated(unsafe) static var languageCode: String = "en"

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = Bundle.main.path(forResource: Self.languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

@Observable
@MainActor
final class LanguageManager {
    var language: AppLanguage = .english
    // Views use .id(lm.version) on their content to force re-render on language change
    // without rebuilding the NavigationStack
    private(set) var version: Int = 0

    init() {
        object_setClass(Bundle.main, LanguageBundle.self)
    }

    func apply(_ lang: AppLanguage) {
        LanguageBundle.languageCode = lang.code
        language = lang
        version += 1
    }

    func L(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
