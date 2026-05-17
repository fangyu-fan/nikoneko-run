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
final class LanguageManager {
    var language: AppLanguage = .english {
        didSet {
            LanguageBundle.languageCode = language.code
            object_setClass(Bundle.main, LanguageBundle.self)
        }
    }

    init() {
        object_setClass(Bundle.main, LanguageBundle.self)
    }

    func apply(_ lang: AppLanguage) {
        language = lang
        LanguageBundle.languageCode = lang.code
    }
}
