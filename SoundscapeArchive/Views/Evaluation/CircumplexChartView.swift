import SwiftUI

/// ISO/TS 12913-2 Circumplex chart visualization
struct CircumplexChartView: View {
    let isoMetrics: ISOMetrics
    let size: CGFloat

    init(isoMetrics: ISOMetrics, size: CGFloat = 250) {
        self.isoMetrics = isoMetrics
        self.size = size
    }

    private var center: CGPoint {
        CGPoint(x: size / 2, y: size / 2)
    }

    private var radius: CGFloat {
        (size - 60) / 2
    }

    var body: some View {
        ZStack {
            // Background quadrants
            quadrantBackgrounds

            // Grid circles
            gridCircles

            // Axis lines
            axisLines

            // Axis labels
            axisLabels

            // Quadrant labels
            quadrantLabels

            // Data point
            dataPoint
        }
        .frame(width: size, height: size)
    }

    // MARK: - Quadrant Backgrounds

    private var quadrantBackgrounds: some View {
        ZStack {
            // Vibrant (top-right)
            QuadrantShape(quadrant: .topRight)
                .fill(Color.orange.opacity(0.1))

            // Chaotic (top-left)
            QuadrantShape(quadrant: .topLeft)
                .fill(Color.red.opacity(0.1))

            // Monotonous (bottom-left)
            QuadrantShape(quadrant: .bottomLeft)
                .fill(Color.gray.opacity(0.1))

            // Calm (bottom-right)
            QuadrantShape(quadrant: .bottomRight)
                .fill(Color.green.opacity(0.1))
        }
        .frame(width: radius * 2, height: radius * 2)
        .clipShape(Circle())
    }

    // MARK: - Grid Circles

    private var gridCircles: some View {
        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                .frame(width: radius * 2 * scale, height: radius * 2 * scale)
        }
    }

    // MARK: - Axis Lines

    private var axisLines: some View {
        ZStack {
            // Horizontal axis (Pleasant - Annoying)
            Path { path in
                path.move(to: CGPoint(x: center.x - radius, y: center.y))
                path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
            }
            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)

            // Vertical axis (Eventful - Uneventful)
            Path { path in
                path.move(to: CGPoint(x: center.x, y: center.y - radius))
                path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
            }
            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
        }
    }

    // MARK: - Axis Labels

    private var axisLabels: some View {
        ZStack {
            // Right: Pleasant
            Text("Pleasant")
                .font(.caption2)
                .position(x: center.x + radius + 25, y: center.y)

            // Left: Annoying
            Text("Annoying")
                .font(.caption2)
                .position(x: center.x - radius - 25, y: center.y)

            // Top: Eventful
            Text("Eventful")
                .font(.caption2)
                .position(x: center.x, y: center.y - radius - 15)

            // Bottom: Uneventful
            Text("Uneventful")
                .font(.caption2)
                .position(x: center.x, y: center.y + radius + 15)
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Quadrant Labels

    private var quadrantLabels: some View {
        let offset = radius * 0.5

        return ZStack {
            // Vibrant (top-right)
            Text("Vibrant")
                .position(x: center.x + offset, y: center.y - offset)

            // Chaotic (top-left)
            Text("Chaotic")
                .position(x: center.x - offset, y: center.y - offset)

            // Monotonous (bottom-left)
            Text("Monotonous")
                .position(x: center.x - offset, y: center.y + offset)

            // Calm (bottom-right)
            Text("Calm")
                .position(x: center.x + offset, y: center.y + offset)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.primary.opacity(0.6))
    }

    // MARK: - Data Point

    private var dataPoint: some View {
        // Convert ISO metrics (-1 to 1) to position
        let x = center.x + CGFloat(isoMetrics.isoPleasant) * radius
        let y = center.y - CGFloat(isoMetrics.isoEventful) * radius

        return ZStack {
            // Point with shadow
            Circle()
                .fill(Color.accentColor)
                .frame(width: 16, height: 16)
                .shadow(color: .accentColor.opacity(0.5), radius: 4)
                .position(x: x, y: y)

            // Line from center to point
            Path { path in
                path.move(to: center)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
        }
    }
}

// MARK: - Quadrant Shape

private struct QuadrantShape: Shape {
    enum Quadrant {
        case topRight, topLeft, bottomLeft, bottomRight
    }

    let quadrant: Quadrant

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let startAngle: Angle
        let endAngle: Angle

        switch quadrant {
        case .topRight:
            startAngle = .degrees(-90)
            endAngle = .degrees(0)
        case .topLeft:
            startAngle = .degrees(-180)
            endAngle = .degrees(-90)
        case .bottomLeft:
            startAngle = .degrees(180)
            endAngle = .degrees(-180)
        case .bottomRight:
            startAngle = .degrees(0)
            endAngle = .degrees(90)
        }

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Compact Circumplex View

struct CompactCircumplexView: View {
    let isoMetrics: ISOMetrics

    var body: some View {
        VStack(spacing: 12) {
            CircumplexChartView(isoMetrics: isoMetrics, size: 200)

            // Metrics display
            HStack(spacing: 24) {
                VStack {
                    Text(String(format: "%.2f", isoMetrics.isoPleasant))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(isoMetrics.isoPleasant >= 0 ? .green : .red)
                    Text("Pleasant")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text(String(format: "%.2f", isoMetrics.isoEventful))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(isoMetrics.isoEventful >= 0 ? .orange : .blue)
                    Text("Eventful")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text(isoMetrics.quadrant.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Quadrant")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        CircumplexChartView(
            isoMetrics: ISOMetrics(
                isoPleasant: 0.4,
                isoEventful: 0.3,
                quadrant: .vibrant
            )
        )

        CompactCircumplexView(
            isoMetrics: ISOMetrics(
                isoPleasant: -0.2,
                isoEventful: 0.5,
                quadrant: .chaotic
            )
        )
    }
    .padding()
}
