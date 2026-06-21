import SwiftUI

/// A color palette applied across the app. Macro colors stay distinct but
/// harmonized to each theme for an elegant, cohesive look.
struct AppTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let accent: Color
    let secondary: Color
    let calories: Color
    let protein: Color
    let carbs: Color
    let fat: Color
    let heat: Color          // base color for the workout heatmap
    let gradient: [Color]    // soft header/card wash

    static let all: [AppTheme] = [classic, lavender, rose, sunset, citrus, mint]

    static func by(id: String) -> AppTheme {
        all.first { $0.id == id } ?? lavender
    }

    // MARK: Presets

    static let lavender = AppTheme(
        id: "lavender", name: "Lavender",
        accent: Color(hex: "8E5BEF"), secondary: Color(hex: "FF8FB1"),
        calories: Color(hex: "B07BE8"), protein: Color(hex: "FF8FB1"),
        carbs: Color(hex: "9D8DF1"), fat: Color(hex: "D7A9F2"),
        heat: Color(hex: "8E5BEF"),
        gradient: [Color(hex: "EBD9FF"), Color(hex: "FBD0E6")]
    )

    static let rose = AppTheme(
        id: "rose", name: "Rosé",
        accent: Color(hex: "E84F8B"), secondary: Color(hex: "F7A6C4"),
        calories: Color(hex: "F2709C"), protein: Color(hex: "E84F8B"),
        carbs: Color(hex: "F4A6B7"), fat: Color(hex: "D98FB0"),
        heat: Color(hex: "E84F8B"),
        gradient: [Color(hex: "FFE0EC"), Color(hex: "FFD3C2")]
    )

    static let sunset = AppTheme(
        id: "sunset", name: "Sunset",
        accent: Color(hex: "FB6F92"), secondary: Color(hex: "FF9E6D"),
        calories: Color(hex: "FF7B54"), protein: Color(hex: "FB6F92"),
        carbs: Color(hex: "FFB26B"), fat: Color(hex: "FFCF6B"),
        heat: Color(hex: "FB6F92"),
        gradient: [Color(hex: "FFD9C0"), Color(hex: "FFC2D6")]
    )

    static let citrus = AppTheme(
        id: "citrus", name: "Citrus",
        accent: Color(hex: "EF7C3B"), secondary: Color(hex: "43AA8B"),
        calories: Color(hex: "FF8C42"), protein: Color(hex: "43AA8B"),
        carbs: Color(hex: "90BE6D"), fat: Color(hex: "F9C74F"),
        heat: Color(hex: "43AA8B"),
        gradient: [Color(hex: "FFE2C0"), Color(hex: "CFE9C8")]
    )

    static let mint = AppTheme(
        id: "mint", name: "Mint",
        accent: Color(hex: "2BB6A3"), secondary: Color(hex: "8ED6C4"),
        calories: Color(hex: "2BB6A3"), protein: Color(hex: "3DA5D9"),
        carbs: Color(hex: "73C2A0"), fat: Color(hex: "9AD0C2"),
        heat: Color(hex: "2BB6A3"),
        gradient: [Color(hex: "D2F2EA"), Color(hex: "CFE9F1")]
    )

    static let classic = AppTheme(
        id: "classic", name: "Classic",
        accent: Color.blue, secondary: Color.pink,
        calories: .orange, protein: .pink, carbs: .blue, fat: .green,
        heat: .green,
        gradient: [Color(hex: "E7F0FF"), Color(hex: "EAF7EE")]
    )

    /// A soft top-to-bottom wash for headers/cards.
    var wash: LinearGradient {
        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// A soft, airy gradient wash behind a scrollable screen. Pair with floating
/// list rows for a light, girly aesthetic.
struct AiryBackground: ViewModifier {
    let theme: AppTheme
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        theme.gradient.first?.opacity(0.55) ?? .clear,
                        (theme.gradient.last ?? .clear).opacity(0.20),
                        Color(.systemBackground),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func airyBackground(_ theme: AppTheme) -> some View {
        modifier(AiryBackground(theme: theme))
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
