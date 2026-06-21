import SwiftUI

/// Design tokens for a theme, mirroring the HTML design's CSS variables.
struct AppTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let page: Color
    let surface: Color
    let surface2: Color
    let ink: Color
    let ink2: Color
    let accent: Color
    let accentDeep: Color
    let accentSoft: Color
    let accentSoft2: Color
    let secondary: Color
    let secondarySoft: Color
    let ring: Color
    let hm: [Color]   // 5 heatmap levels, light → dark

    static let all: [AppTheme] = [fairy, seaside]
    static func by(id: String) -> AppTheme { all.first { $0.id == id } ?? fairy }

    /// A small two-color wash for the theme swatch chip.
    var swatch: LinearGradient {
        LinearGradient(colors: [accent, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let fairy = AppTheme(
        id: "fairy", name: "Fairy Garden", emoji: "🌿",
        page: Color(hex: "F4F2EC"), surface: .white, surface2: Color(hex: "F4F2EA"),
        ink: Color(hex: "36412F"), ink2: Color(hex: "8B9583"),
        accent: Color(hex: "6E8A66"), accentDeep: Color(hex: "4C5F44"),
        accentSoft: Color(hex: "CFDCC2"), accentSoft2: Color(hex: "ECF1E5"),
        secondary: Color(hex: "BFA06A"), secondarySoft: Color(hex: "EFE6D2"),
        ring: Color(hex: "506446").opacity(0.12),
        hm: ["E7E9E0", "C7D6BB", "9DB98C", "6E8A66", "3E4F39"].map { Color(hex: $0) }
    )

    static let seaside = AppTheme(
        id: "seaside", name: "Orange Seaside", emoji: "🍊",
        page: Color(hex: "FBF4EB"), surface: .white, surface2: Color(hex: "FBF2E8"),
        ink: Color(hex: "4B4036"), ink2: Color(hex: "A7988A"),
        accent: Color(hex: "ED9442"), accentDeep: Color(hex: "D2731F"),
        accentSoft: Color(hex: "FBDCBE"), accentSoft2: Color(hex: "FCEEDF"),
        secondary: Color(hex: "8FBCCD"), secondarySoft: Color(hex: "DDEBF0"),
        ring: Color(hex: "96785A").opacity(0.13),
        hm: ["EFE6DC", "F8D9BC", "F4B97E", "ED9442", "DA7321"].map { Color(hex: $0) }
    )
}

// MARK: - Typography (Marcellus serif headings, Quicksand rounded body)

extension Font {
    /// Marcellus serif — for titles, numbers, hero text.
    static func serif(_ size: CGFloat) -> Font { .custom("Marcellus", size: size) }
    /// Quicksand — body / labels.
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .custom("Quicksand", size: size).weight(weight)
    }
}

// MARK: - Reusable styling

extension View {
    /// White rounded card with a soft shadow.
    func glowCard(_ t: AppTheme, padding: CGFloat = 16, radius: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(t.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color(hex: "46503C").opacity(0.06), radius: 10, x: 0, y: 3)
    }

    /// Flat cream page background behind a scroll view / list.
    func airyBackground(_ t: AppTheme) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(t.page.ignoresSafeArea())
    }

    /// Uppercase tracked section label (Quicksand 700).
    func sectionLabel() -> some View {
        self.font(.sans(12, .bold))
            .textCase(.uppercase)
            .kerning(1.0)
    }
}

extension Color {
    /// Hex like "FF8FB1" or "#FF8FB1".
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
