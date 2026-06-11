import SwiftUI

struct BlobShape: Shape {
    var animationProgress: CGFloat = 0

    var animatableData: CGFloat {
        get { animationProgress }
        set { animationProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2.5
        let t  = animationProgress

        let points: [CGPoint] = (0..<6).map { i in
            let baseAngle = CGFloat(i) * .pi / 3
            let variance  = sin(t * .pi * 2 + CGFloat(i) * 0.8) * r * 0.22
            let radius    = r + variance
            return CGPoint(x: cx + radius * cos(baseAngle),
                           y: cy + radius * sin(baseAngle))
        }

        return Path { path in
            path.move(to: points[0])
            for i in 0..<points.count {
                let next = points[(i + 1) % points.count]
                let curr = points[i]
                let cp1  = CGPoint(x: curr.x + (next.x - curr.x) / 3,
                                   y: curr.y + (next.y - curr.y) / 3)
                let cp2  = CGPoint(x: next.x - (next.x - curr.x) / 3,
                                   y: next.y - (next.y - curr.y) / 3)
                path.addCurve(to: next, control1: cp1, control2: cp2)
            }
            path.closeSubpath()
        }
    }
}
