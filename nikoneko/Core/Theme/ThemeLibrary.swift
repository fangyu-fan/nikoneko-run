import SwiftUI

enum ThemeLibrary {
    static let all: [ThemeTokens] = [
        obsidian, paper, limestone, zinc,
        grove, moss, mocha, seafloor,
        skyline, navy, lavender, midnight, teal, blush
    ]

    static let obsidian = ThemeTokens(
        id: "obsidian",
        bg:         Color(hex: "0a0a0a"),
        surface:    Color(hex: "141414"),
        card:       Color(hex: "111111"),
        text:       Color(hex: "f0ede8"),
        textDim:    Color(hex: "2e2e2e"),
        textMid:    Color(hex: "666666"),
        accent:     Color(hex: "f0ede8"),
        accentMid:  Color(hex: "888888"),
        accentDim:  Color(hex: "1e1e1e"),
        bar: [Color(hex:"1a1a1a"), Color(hex:"2e2e2e"), Color(hex:"4a4a4a"), Color(hex:"888888"), Color(hex:"f0ede8")],
        cal: [Color(hex:"1a1a1a"), Color(hex:"2e2e2e"), Color(hex:"4a4a4a"), Color(hex:"888888"), Color(hex:"f0ede8")],
        isDark: true
    )

    static let paper = ThemeTokens(
        id: "paper",
        bg:         Color(hex: "ffffff"),
        surface:    Color(hex: "f5f5f5"),
        card:       Color(hex: "ebebeb"),
        text:       Color(hex: "111111"),
        textDim:    Color(hex: "aaaaaa"),
        textMid:    Color(hex: "555555"),
        accent:     Color(hex: "111111"),
        accentMid:  Color(hex: "555555"),
        accentDim:  Color(hex: "dddddd"),
        bar: [Color(hex:"e8e8e8"), Color(hex:"cccccc"), Color(hex:"aaaaaa"), Color(hex:"555555"), Color(hex:"111111")],
        cal: [Color(hex:"e8e8e8"), Color(hex:"cccccc"), Color(hex:"aaaaaa"), Color(hex:"555555"), Color(hex:"111111")],
        isDark: false
    )

    static let limestone = ThemeTokens(
        id: "limestone",
        bg:         Color(hex: "f4f0ea"),
        surface:    Color(hex: "ece8e0"),
        card:       Color(hex: "e4dfd6"),
        text:       Color(hex: "1c1a16"),
        textDim:    Color(hex: "b8b0a0"),
        textMid:    Color(hex: "888070"),
        accent:     Color(hex: "3c3830"),
        accentMid:  Color(hex: "908070"),
        accentDim:  Color(hex: "d0c8b8"),
        bar: [Color(hex:"e4dfd6"), Color(hex:"ccc4b4"), Color(hex:"a89880"), Color(hex:"806850"), Color(hex:"3c3830")],
        cal: [Color(hex:"e4dfd6"), Color(hex:"ccc4b4"), Color(hex:"a89880"), Color(hex:"806850"), Color(hex:"3c3830")],
        isDark: false
    )

    static let zinc = ThemeTokens(
        id: "zinc",
        bg:         Color(hex: "0d1117"),
        surface:    Color(hex: "161b22"),
        card:       Color(hex: "21262d"),
        text:       Color(hex: "e6edf3"),
        textDim:    Color(hex: "30363d"),
        textMid:    Color(hex: "8b949e"),
        accent:     Color(hex: "58a6ff"),
        accentMid:  Color(hex: "79c0ff"),
        accentDim:  Color(hex: "0d2a4a"),
        bar: [Color(hex:"161b22"), Color(hex:"0a2a1a"), Color(hex:"006d32"), Color(hex:"26a641"), Color(hex:"39d353")],
        cal: [Color(hex:"161b22"), Color(hex:"0a2a1a"), Color(hex:"006d32"), Color(hex:"26a641"), Color(hex:"39d353")],
        isDark: true
    )

    static let grove = ThemeTokens(
        id: "grove",
        bg:         Color(hex: "F5ECD7"),
        surface:    Color(hex: "ebe2cd"),
        card:       Color(hex: "ddd4bc"),
        text:       Color(hex: "353535"),
        textDim:    Color(hex: "5f5f5f"),
        textMid:    Color(hex: "68a67d"),
        accent:     Color(hex: "8FBF9F"),
        accentMid:  Color(hex: "24613b"),
        accentDim:  Color(hex: "c8ddd0"),
        bar: [Color(hex:"c8ddd0"), Color(hex:"98c8a8"), Color(hex:"68a67d"), Color(hex:"24613b"), Color(hex:"F18F01")],
        cal: [Color(hex:"c8ddd0"), Color(hex:"98c8a8"), Color(hex:"68a67d"), Color(hex:"24613b"), Color(hex:"F18F01")],
        isDark: false
    )

    static let moss = ThemeTokens(
        id: "moss",
        bg:         Color(hex: "DDDDDD"),
        surface:    Color(hex: "EEEEEE"),
        card:       Color(hex: "e4e4e4"),
        text:       Color(hex: "292524"),
        textDim:    Color(hex: "78716c"),
        textMid:    Color(hex: "658864"),
        accent:     Color(hex: "658864"),
        accentMid:  Color(hex: "4a6848"),
        accentDim:  Color(hex: "B7B78A"),
        bar: [Color(hex:"B7B78A"), Color(hex:"9aaa70"), Color(hex:"658864"), Color(hex:"4a6848"), Color(hex:"bc6c25")],
        cal: [Color(hex:"B7B78A"), Color(hex:"9aaa70"), Color(hex:"658864"), Color(hex:"4a6848"), Color(hex:"bc6c25")],
        isDark: false
    )

    static let mocha = ThemeTokens(
        id: "mocha",
        bg:         Color(hex: "1a1210"),
        surface:    Color(hex: "241a14"),
        card:       Color(hex: "1e1510"),
        text:       Color(hex: "e8d5c0"),
        textDim:    Color(hex: "4a3020"),
        textMid:    Color(hex: "b08060"),
        accent:     Color(hex: "c8956a"),
        accentMid:  Color(hex: "a07048"),
        accentDim:  Color(hex: "301e10"),
        bar: [Color(hex:"241a14"), Color(hex:"4a2c18"), Color(hex:"7a4828"), Color(hex:"b07040"), Color(hex:"c8956a")],
        cal: [Color(hex:"241a14"), Color(hex:"4a2c18"), Color(hex:"7a4828"), Color(hex:"b07040"), Color(hex:"c8956a")],
        isDark: true
    )

    static let seafloor = ThemeTokens(
        id: "seafloor",
        bg:         Color(hex: "567189"),
        surface:    Color(hex: "7B8FA1"),
        card:       Color(hex: "6a8098"),
        text:       Color(hex: "F9F9F9"),
        textDim:    Color(hex: "DCDCDC"),
        textMid:    Color(hex: "CFB997"),
        accent:     Color(hex: "f7bf7a"),
        accentMid:  Color(hex: "e8a050"),
        accentDim:  Color(hex: "3E5975"),
        bar: [Color(hex:"3E5975"), Color(hex:"5a7898"), Color(hex:"7B8FA1"), Color(hex:"f7bf7a"), Color(hex:"CFB997")],
        cal: [Color(hex:"3E5975"), Color(hex:"5a7898"), Color(hex:"7B8FA1"), Color(hex:"f7bf7a"), Color(hex:"CFB997")],
        isDark: true
    )

    static let skyline = ThemeTokens(
        id: "skyline",
        bg:         Color(hex: "fffefb"),
        surface:    Color(hex: "f5f4f1"),
        card:       Color(hex: "e8e6e2"),
        text:       Color(hex: "1d1c1c"),
        textDim:    Color(hex: "313d44"),
        textMid:    Color(hex: "3b3c3d"),
        accent:     Color(hex: "71c4ef"),
        accentMid:  Color(hex: "00668c"),
        accentDim:  Color(hex: "d4eaf7"),
        bar: [Color(hex:"d4eaf7"), Color(hex:"b6ccd8"), Color(hex:"71c4ef"), Color(hex:"00668c"), Color(hex:"1d1c1c")],
        cal: [Color(hex:"d4eaf7"), Color(hex:"b6ccd8"), Color(hex:"71c4ef"), Color(hex:"00668c"), Color(hex:"1d1c1c")],
        isDark: false
    )

    static let navy = ThemeTokens(
        id: "navy",
        bg:         Color(hex: "0F1C2E"),
        surface:    Color(hex: "1f2b3e"),
        card:       Color(hex: "2a3650"),
        text:       Color(hex: "FFFFFF"),
        textDim:    Color(hex: "e0e0e0"),
        textMid:    Color(hex: "4d648d"),
        accent:     Color(hex: "acc2ef"),
        accentMid:  Color(hex: "3D5A80"),
        accentDim:  Color(hex: "1F3A5F"),
        bar: [Color(hex:"1F3A5F"), Color(hex:"2e5080"), Color(hex:"4d648d"), Color(hex:"acc2ef"), Color(hex:"cee8ff")],
        cal: [Color(hex:"1F3A5F"), Color(hex:"2e5080"), Color(hex:"4d648d"), Color(hex:"acc2ef"), Color(hex:"cee8ff")],
        isDark: true
    )

    static let lavender = ThemeTokens(
        id: "lavender",
        bg:         Color(hex: "F5F3F7"),
        surface:    Color(hex: "E9E4ED"),
        card:       Color(hex: "ddd6e4"),
        text:       Color(hex: "4A4A4A"),
        textDim:    Color(hex: "878787"),
        textMid:    Color(hex: "9A73B5"),
        accent:     Color(hex: "8B5FBF"),
        accentMid:  Color(hex: "61398F"),
        accentDim:  Color(hex: "D6C6E1"),
        bar: [Color(hex:"D6C6E1"), Color(hex:"c4a8d8"), Color(hex:"9A73B5"), Color(hex:"8B5FBF"), Color(hex:"61398F")],
        cal: [Color(hex:"D6C6E1"), Color(hex:"c4a8d8"), Color(hex:"9A73B5"), Color(hex:"8B5FBF"), Color(hex:"61398F")],
        isDark: false
    )

    static let midnight = ThemeTokens(
        id: "midnight",
        bg:         Color(hex: "151931"),
        surface:    Color(hex: "252841"),
        card:       Color(hex: "2e3150"),
        text:       Color(hex: "E7D1BB"),
        textDim:    Color(hex: "847a86"),
        textMid:    Color(hex: "A096A5"),
        accent:     Color(hex: "A096A5"),
        accentMid:  Color(hex: "c8b4c0"),
        accentDim:  Color(hex: "463e4b"),
        bar: [Color(hex:"2e3150"), Color(hex:"463e4b"), Color(hex:"706070"), Color(hex:"A096A2"), Color(hex:"E7D1BB")],
        cal: [Color(hex:"2e3150"), Color(hex:"463e4b"), Color(hex:"706070"), Color(hex:"A096A2"), Color(hex:"E7D1BB")],
        isDark: true
    )

    static let teal = ThemeTokens(
        id: "teal",
        bg:         Color(hex: "F2EFE9"),
        surface:    Color(hex: "e8e5df"),
        card:       Color(hex: "dddad4"),
        text:       Color(hex: "333333"),
        textDim:    Color(hex: "5c5c5c"),
        textMid:    Color(hex: "008b7a"),
        accent:     Color(hex: "00A896"),
        accentMid:  Color(hex: "006b60"),
        accentDim:  Color(hex: "a0d8d0"),
        bar: [Color(hex:"a0d8d0"), Color(hex:"50c0b0"), Color(hex:"00A896"), Color(hex:"006b60"), Color(hex:"FF6B6B")],
        cal: [Color(hex:"a0d8d0"), Color(hex:"50c0b0"), Color(hex:"00A896"), Color(hex:"006b60"), Color(hex:"FF6B6B")],
        isDark: false
    )

    static let blush = ThemeTokens(
        id: "blush",
        bg:         Color(hex: "FCEEF5"),
        surface:    Color(hex: "ffffff"),
        card:       Color(hex: "FAD9E6"),
        text:       Color(hex: "292524"),
        textDim:    Color(hex: "78716c"),
        textMid:    Color(hex: "61C0BF"),
        accent:     Color(hex: "61C0BF"),
        accentMid:  Color(hex: "3a9898"),
        accentDim:  Color(hex: "BBDED6"),
        bar: [Color(hex:"FAD9E6"), Color(hex:"FFB6B9"), Color(hex:"e89090"), Color(hex:"61C0BF"), Color(hex:"3a9898")],
        cal: [Color(hex:"FAD9E6"), Color(hex:"FFB6B9"), Color(hex:"e89090"), Color(hex:"61C0BF"), Color(hex:"3a9898")],
        isDark: false
    )
}
