import XCTest
import SwiftUI
@testable import nikoneko

final class ThemeLibraryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "activeThemeId")
        UserDefaults(suiteName: AppGroupDefaults.suiteName)?.removeObject(forKey: "activeThemeId")
    }

    func test_allThemesExist() {
        XCTAssertEqual(ThemeLibrary.all.count, 14)
    }

    func test_allThemesHaveFiveBarStops() {
        for theme in ThemeLibrary.all {
            XCTAssertEqual(theme.bar.count, 5,
                "\(theme.id) has \(theme.bar.count) bar stops, expected 5")
        }
    }

    func test_allThemesHaveFiveCalStops() {
        for theme in ThemeLibrary.all {
            XCTAssertEqual(theme.cal.count, 5,
                "\(theme.id) has \(theme.cal.count) cal stops, expected 5")
        }
    }

    func test_allThemeIdsAreUnique() {
        let ids = ThemeLibrary.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func test_themeManagerDefaultIsObsidian() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.current.id, "obsidian")
    }

    func test_themeManagerApplyChangesCurrentTheme() {
        let manager = ThemeManager()
        manager.apply("paper")
        XCTAssertEqual(manager.current.id, "paper")
    }

    func test_themeManagerIgnoresUnknownId() {
        let manager = ThemeManager()
        manager.apply("nonexistent")
        XCTAssertEqual(manager.current.id, "obsidian")
    }

    func test_colorHexInitializer() {
        let white = Color(hex: "ffffff")
        XCTAssertNotNil(white)
    }
}
