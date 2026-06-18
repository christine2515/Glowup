import SwiftUI

/// A circular progress ring for a single macro / calorie metric.
struct MacroRing: View {
    let label: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color
    var lineWidth: CGFloat = 8

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1)
    }
    private var over: Bool { value > target && target > 0 }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(over ? Color.red : color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.headline)
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 76, height: 76)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("/ \(Int(target))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Daily macro totals.
struct MacroTotals {
    var kcal: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}
