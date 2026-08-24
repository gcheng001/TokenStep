import AppKit
import SwiftUI

struct TokenStepRGB: Equatable {
    var red: Double
    var green: Double
    var blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var nsColor: NSColor {
        NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
    }
}

struct TokenStepThemePalette {
    var canvas: TokenStepRGB
    var surface: TokenStepRGB
    var accent: TokenStepRGB
    var accentDark: TokenStepRGB
    var accentSoft: TokenStepRGB
    var track: TokenStepRGB
    var lowActivity: TokenStepRGB
    var activity1: TokenStepRGB
    var activity2: TokenStepRGB
    var activity3: TokenStepRGB
    var activity4: TokenStepRGB
    var ring1: TokenStepRGB
    var ring2: TokenStepRGB
    var ring3: TokenStepRGB
    var ring4: TokenStepRGB

    func ringRGB(for lap: Int) -> TokenStepRGB {
        switch max(lap, 1) {
        case 1: return ring1
        case 2: return ring2
        case 3: return ring3
        default: return ring4
        }
    }

    func activityColor(for level: Int) -> Color {
        switch level {
        case 1: return activity1.color
        case 2: return activity2.color
        case 3: return activity3.color
        default: return activity4.color
        }
    }
}

enum TokenStepThemePack: String, CaseIterable, Identifiable, Codable {
    case classic
    case odyssey

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return L("经典")
        case .odyssey: return L("奥德赛")
        }
    }

    var subtitle: String {
        switch self {
        case .classic: return L("原版 TokenStep")
        case .odyssey: return L("冷雾 · 骨金 · 火星")
        }
    }
}

enum TokenStepOdysseyChapter: String, CaseIterable, Identifiable, Codable {
    case directorsCut = "directors_cut"
    case aegeanMist = "aegean_mist"
    case trojanInferno = "trojan_inferno"
    case ashMarble = "ash_marble"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .directorsCut: return L("导演剪辑")
        case .aegeanMist: return L("爱琴海冷雾")
        case .trojanInferno: return L("特洛伊火海")
        case .ashMarble: return L("灰烬神像")
        }
    }

    var subtitle: String {
        switch self {
        case .directorsCut: return L("按界面自动组合")
        case .aegeanMist: return L("头盔 · 冷雾 · 深海")
        case .trojanInferno: return L("木马 · 烈火 · 余烬")
        case .ashMarble: return L("神像 · 石纹 · 灰烬")
        }
    }

    var editionLabel: String {
        switch self {
        case .directorsCut: return "ODYSSEY · DIRECTOR'S CUT"
        case .aegeanMist: return "ODYSSEY · AEGEAN MIST"
        case .trojanInferno: return "ODYSSEY · TROJAN INFERNO"
        case .ashMarble: return "ODYSSEY · ASH & MARBLE"
        }
    }

    var symbol: String {
        switch self {
        case .directorsCut: return "sparkles.rectangle.stack.fill"
        case .aegeanMist: return "cloud.fog.fill"
        case .trojanInferno: return "flame.fill"
        case .ashMarble: return "building.columns.fill"
        }
    }

    var palette: TokenStepThemePalette {
        switch self {
        case .directorsCut:
            return TokenStepThemePalette(
                canvas: .init(red: 7 / 255, green: 15 / 255, blue: 22 / 255),
                surface: .init(red: 16 / 255, green: 26 / 255, blue: 33 / 255),
                accent: .init(red: 202 / 255, green: 158 / 255, blue: 91 / 255),
                accentDark: .init(red: 232 / 255, green: 196 / 255, blue: 129 / 255),
                accentSoft: .init(red: 61 / 255, green: 53 / 255, blue: 42 / 255),
                track: .init(red: 46 / 255, green: 54 / 255, blue: 59 / 255),
                lowActivity: .init(red: 50 / 255, green: 56 / 255, blue: 58 / 255),
                activity1: .init(red: 111 / 255, green: 92 / 255, blue: 66 / 255),
                activity2: .init(red: 151 / 255, green: 119 / 255, blue: 74 / 255),
                activity3: .init(red: 190 / 255, green: 143 / 255, blue: 77 / 255),
                activity4: .init(red: 222 / 255, green: 179 / 255, blue: 107 / 255),
                ring1: .init(red: 202 / 255, green: 158 / 255, blue: 91 / 255),
                ring2: .init(red: 218 / 255, green: 176 / 255, blue: 106 / 255),
                ring3: .init(red: 232 / 255, green: 196 / 255, blue: 129 / 255),
                ring4: .init(red: 244 / 255, green: 216 / 255, blue: 164 / 255)
            )
        case .aegeanMist:
            return TokenStepThemePalette(
                canvas: .init(red: 5 / 255, green: 18 / 255, blue: 29 / 255),
                surface: .init(red: 13 / 255, green: 31 / 255, blue: 43 / 255),
                accent: .init(red: 198 / 255, green: 158 / 255, blue: 91 / 255),
                accentDark: .init(red: 225 / 255, green: 194 / 255, blue: 134 / 255),
                accentSoft: .init(red: 57 / 255, green: 75 / 255, blue: 84 / 255),
                track: .init(red: 42 / 255, green: 63 / 255, blue: 75 / 255),
                lowActivity: .init(red: 48 / 255, green: 73 / 255, blue: 88 / 255),
                activity1: .init(red: 92 / 255, green: 119 / 255, blue: 132 / 255),
                activity2: .init(red: 129 / 255, green: 143 / 255, blue: 134 / 255),
                activity3: .init(red: 174 / 255, green: 150 / 255, blue: 99 / 255),
                activity4: .init(red: 215 / 255, green: 181 / 255, blue: 116 / 255),
                ring1: .init(red: 198 / 255, green: 158 / 255, blue: 91 / 255),
                ring2: .init(red: 215 / 255, green: 179 / 255, blue: 111 / 255),
                ring3: .init(red: 228 / 255, green: 200 / 255, blue: 146 / 255),
                ring4: .init(red: 240 / 255, green: 221 / 255, blue: 181 / 255)
            )
        case .trojanInferno:
            return TokenStepThemePalette(
                canvas: .init(red: 10 / 255, green: 9 / 255, blue: 8 / 255),
                surface: .init(red: 25 / 255, green: 20 / 255, blue: 17 / 255),
                accent: .init(red: 209 / 255, green: 122 / 255, blue: 55 / 255),
                accentDark: .init(red: 239 / 255, green: 170 / 255, blue: 92 / 255),
                accentSoft: .init(red: 75 / 255, green: 40 / 255, blue: 25 / 255),
                track: .init(red: 58 / 255, green: 45 / 255, blue: 37 / 255),
                lowActivity: .init(red: 61 / 255, green: 38 / 255, blue: 28 / 255),
                activity1: .init(red: 111 / 255, green: 57 / 255, blue: 35 / 255),
                activity2: .init(red: 160 / 255, green: 78 / 255, blue: 39 / 255),
                activity3: .init(red: 205 / 255, green: 105 / 255, blue: 47 / 255),
                activity4: .init(red: 238 / 255, green: 154 / 255, blue: 77 / 255),
                ring1: .init(red: 209 / 255, green: 122 / 255, blue: 55 / 255),
                ring2: .init(red: 226 / 255, green: 143 / 255, blue: 67 / 255),
                ring3: .init(red: 239 / 255, green: 170 / 255, blue: 92 / 255),
                ring4: .init(red: 248 / 255, green: 198 / 255, blue: 128 / 255)
            )
        case .ashMarble:
            return TokenStepThemePalette(
                canvas: .init(red: 13 / 255, green: 14 / 255, blue: 15 / 255),
                surface: .init(red: 25 / 255, green: 27 / 255, blue: 28 / 255),
                accent: .init(red: 190 / 255, green: 149 / 255, blue: 96 / 255),
                accentDark: .init(red: 222 / 255, green: 189 / 255, blue: 139 / 255),
                accentSoft: .init(red: 64 / 255, green: 62 / 255, blue: 58 / 255),
                track: .init(red: 55 / 255, green: 56 / 255, blue: 55 / 255),
                lowActivity: .init(red: 66 / 255, green: 65 / 255, blue: 61 / 255),
                activity1: .init(red: 104 / 255, green: 99 / 255, blue: 88 / 255),
                activity2: .init(red: 139 / 255, green: 119 / 255, blue: 91 / 255),
                activity3: .init(red: 178 / 255, green: 143 / 255, blue: 96 / 255),
                activity4: .init(red: 215 / 255, green: 177 / 255, blue: 124 / 255),
                ring1: .init(red: 190 / 255, green: 149 / 255, blue: 96 / 255),
                ring2: .init(red: 208 / 255, green: 169 / 255, blue: 116 / 255),
                ring3: .init(red: 222 / 255, green: 189 / 255, blue: 139 / 255),
                ring4: .init(red: 237 / 255, green: 213 / 255, blue: 175 / 255)
            )
        }
    }
}

enum TokenStepTheme: String, CaseIterable, Identifiable, Codable {
    case green
    case ocean
    case violet
    case amber
    case graphite
    case voyage

    static let classicCases: [TokenStepTheme] = [.green, .ocean, .violet, .amber, .graphite]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .green: return L("青绿")
        case .ocean: return L("海蓝")
        case .violet: return L("紫藤")
        case .amber: return L("琥珀")
        case .graphite: return L("石墨")
        case .voyage: return L("奥德赛")
        }
    }

    var subtitle: String {
        switch self {
        case .green: return L("默认")
        case .ocean: return L("清爽")
        case .violet: return "Agent"
        case .amber: return L("温暖")
        case .graphite: return L("专注")
        case .voyage: return L("主题皮肤包")
        }
    }

    var colorScheme: ColorScheme {
        self == .voyage ? .dark : .light
    }

    var inkColor: Color {
        self == .voyage
            ? Color(red: 231 / 255, green: 221 / 255, blue: 200 / 255)
            : Color(red: 31 / 255, green: 41 / 255, blue: 55 / 255)
    }

    var dividerColor: Color {
        self == .voyage
            ? Color(red: 116 / 255, green: 82 / 255, blue: 49 / 255).opacity(0.58)
            : Color.black.opacity(0.06)
    }

    var palette: TokenStepThemePalette {
        switch self {
        case .green:
            return TokenStepThemePalette(
                canvas: .init(red: 246 / 255, green: 248 / 255, blue: 250 / 255),
                surface: .init(red: 255 / 255, green: 255 / 255, blue: 255 / 255),
                accent: .init(red: 45 / 255, green: 164 / 255, blue: 78 / 255),
                accentDark: .init(red: 33 / 255, green: 110 / 255, blue: 57 / 255),
                accentSoft: .init(red: 155 / 255, green: 233 / 255, blue: 168 / 255),
                track: .init(red: 235 / 255, green: 237 / 255, blue: 240 / 255),
                lowActivity: .init(red: 221 / 255, green: 244 / 255, blue: 223 / 255),
                activity1: .init(red: 155 / 255, green: 233 / 255, blue: 168 / 255),
                activity2: .init(red: 64 / 255, green: 196 / 255, blue: 99 / 255),
                activity3: .init(red: 48 / 255, green: 161 / 255, blue: 78 / 255),
                activity4: .init(red: 33 / 255, green: 110 / 255, blue: 57 / 255),
                ring1: .init(red: 64 / 255, green: 196 / 255, blue: 99 / 255),
                ring2: .init(red: 48 / 255, green: 161 / 255, blue: 78 / 255),
                ring3: .init(red: 33 / 255, green: 110 / 255, blue: 57 / 255),
                ring4: .init(red: 14 / 255, green: 68 / 255, blue: 41 / 255)
            )
        case .ocean:
            return TokenStepThemePalette(
                canvas: .init(red: 245 / 255, green: 250 / 255, blue: 253 / 255),
                surface: .init(red: 254 / 255, green: 255 / 255, blue: 255 / 255),
                accent: .init(red: 14 / 255, green: 165 / 255, blue: 233 / 255),
                accentDark: .init(red: 3 / 255, green: 105 / 255, blue: 161 / 255),
                accentSoft: .init(red: 186 / 255, green: 230 / 255, blue: 253 / 255),
                track: .init(red: 234 / 255, green: 240 / 255, blue: 245 / 255),
                lowActivity: .init(red: 224 / 255, green: 242 / 255, blue: 254 / 255),
                activity1: .init(red: 186 / 255, green: 230 / 255, blue: 253 / 255),
                activity2: .init(red: 56 / 255, green: 189 / 255, blue: 248 / 255),
                activity3: .init(red: 14 / 255, green: 165 / 255, blue: 233 / 255),
                activity4: .init(red: 3 / 255, green: 105 / 255, blue: 161 / 255),
                ring1: .init(red: 56 / 255, green: 189 / 255, blue: 248 / 255),
                ring2: .init(red: 14 / 255, green: 165 / 255, blue: 233 / 255),
                ring3: .init(red: 2 / 255, green: 132 / 255, blue: 199 / 255),
                ring4: .init(red: 7 / 255, green: 89 / 255, blue: 133 / 255)
            )
        case .violet:
            return TokenStepThemePalette(
                canvas: .init(red: 250 / 255, green: 248 / 255, blue: 255 / 255),
                surface: .init(red: 255 / 255, green: 254 / 255, blue: 255 / 255),
                accent: .init(red: 139 / 255, green: 92 / 255, blue: 246 / 255),
                accentDark: .init(red: 91 / 255, green: 33 / 255, blue: 182 / 255),
                accentSoft: .init(red: 221 / 255, green: 214 / 255, blue: 254 / 255),
                track: .init(red: 238 / 255, green: 235 / 255, blue: 245 / 255),
                lowActivity: .init(red: 237 / 255, green: 233 / 255, blue: 254 / 255),
                activity1: .init(red: 221 / 255, green: 214 / 255, blue: 254 / 255),
                activity2: .init(red: 167 / 255, green: 139 / 255, blue: 250 / 255),
                activity3: .init(red: 139 / 255, green: 92 / 255, blue: 246 / 255),
                activity4: .init(red: 91 / 255, green: 33 / 255, blue: 182 / 255),
                ring1: .init(red: 167 / 255, green: 139 / 255, blue: 250 / 255),
                ring2: .init(red: 139 / 255, green: 92 / 255, blue: 246 / 255),
                ring3: .init(red: 109 / 255, green: 40 / 255, blue: 217 / 255),
                ring4: .init(red: 76 / 255, green: 29 / 255, blue: 149 / 255)
            )
        case .amber:
            return TokenStepThemePalette(
                canvas: .init(red: 255 / 255, green: 250 / 255, blue: 242 / 255),
                surface: .init(red: 255 / 255, green: 255 / 255, blue: 252 / 255),
                accent: .init(red: 245 / 255, green: 158 / 255, blue: 11 / 255),
                accentDark: .init(red: 180 / 255, green: 83 / 255, blue: 9 / 255),
                accentSoft: .init(red: 253 / 255, green: 230 / 255, blue: 138 / 255),
                track: .init(red: 244 / 255, green: 239 / 255, blue: 231 / 255),
                lowActivity: .init(red: 254 / 255, green: 243 / 255, blue: 199 / 255),
                activity1: .init(red: 254 / 255, green: 243 / 255, blue: 199 / 255),
                activity2: .init(red: 251 / 255, green: 191 / 255, blue: 36 / 255),
                activity3: .init(red: 245 / 255, green: 158 / 255, blue: 11 / 255),
                activity4: .init(red: 180 / 255, green: 83 / 255, blue: 9 / 255),
                ring1: .init(red: 251 / 255, green: 191 / 255, blue: 36 / 255),
                ring2: .init(red: 245 / 255, green: 158 / 255, blue: 11 / 255),
                ring3: .init(red: 180 / 255, green: 83 / 255, blue: 9 / 255),
                ring4: .init(red: 120 / 255, green: 53 / 255, blue: 15 / 255)
            )
        case .graphite:
            return TokenStepThemePalette(
                canvas: .init(red: 247 / 255, green: 247 / 255, blue: 247 / 255),
                surface: .init(red: 255 / 255, green: 255 / 255, blue: 255 / 255),
                accent: .init(red: 82 / 255, green: 82 / 255, blue: 91 / 255),
                accentDark: .init(red: 39 / 255, green: 39 / 255, blue: 42 / 255),
                accentSoft: .init(red: 212 / 255, green: 212 / 255, blue: 216 / 255),
                track: .init(red: 232 / 255, green: 232 / 255, blue: 236 / 255),
                lowActivity: .init(red: 228 / 255, green: 228 / 255, blue: 231 / 255),
                activity1: .init(red: 212 / 255, green: 212 / 255, blue: 216 / 255),
                activity2: .init(red: 113 / 255, green: 113 / 255, blue: 122 / 255),
                activity3: .init(red: 82 / 255, green: 82 / 255, blue: 91 / 255),
                activity4: .init(red: 39 / 255, green: 39 / 255, blue: 42 / 255),
                ring1: .init(red: 113 / 255, green: 113 / 255, blue: 122 / 255),
                ring2: .init(red: 82 / 255, green: 82 / 255, blue: 91 / 255),
                ring3: .init(red: 63 / 255, green: 63 / 255, blue: 70 / 255),
                ring4: .init(red: 24 / 255, green: 24 / 255, blue: 27 / 255)
            )
        case .voyage:
            return TokenStepOdysseyChapter.directorsCut.palette
        }
    }
}

enum TokenStepThemeRuntime {
    private static var activeTheme: TokenStepTheme = .green
    private static var activeOdysseyChapter: TokenStepOdysseyChapter = .directorsCut

    static var theme: TokenStepTheme { activeTheme }
    static var palette: TokenStepThemePalette {
        isOdyssey ? activeOdysseyChapter.palette : activeTheme.palette
    }
    static var isOdyssey: Bool { activeTheme == .voyage }
    static var isVoyage: Bool { isOdyssey }
    static var odysseyChapter: TokenStepOdysseyChapter { activeOdysseyChapter }
    static var themePack: TokenStepThemePack { isOdyssey ? .odyssey : .classic }

    static func apply(
        _ theme: TokenStepTheme,
        odysseyChapter: TokenStepOdysseyChapter = .directorsCut
    ) {
        activeTheme = theme
        activeOdysseyChapter = odysseyChapter
    }
}
