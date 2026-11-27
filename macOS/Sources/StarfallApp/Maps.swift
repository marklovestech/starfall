import StarfallCore
import SwiftUI

struct WorldMap: View {
    let world: World
    let cursor: Block
    let waypoints: Set<Block>
    let terrain: CGImage
    let select: (Block) -> Void

    var body: some View {
        GeometryReader { area in
            let cellW = area.size.width / CGFloat(Block.width)
            let cellH = area.size.height / CGFloat(Block.height)
            ZStack {
                Image(decorative: terrain, scale: 1)
                    .resizable()
                    .interpolation(.none)
                Canvas { context, size in
                    for block in world.occupied {
                        dot(context, block, .terminal, cellW, cellH, 2)
                    }
                    for item in world.pending where item.action == .transportation {
                        if let block = item.route.first?.block { dot(context, block, .cyan, cellW, cellH, 2) }
                    }
                    for block in waypoints {
                        dot(context, block, .white, cellW, cellH, 2)
                    }
                    if let base = world.base {
                        dot(context, base, .signal, cellW, cellH, 3)
                    }
                    let selected = point(cursor, cellW, cellH)
                    let rect = CGRect(x: selected.x - 4.5 * cellW, y: selected.y - 4.5 * cellH,
                                      width: 9 * cellW, height: 9 * cellH)
                    context.stroke(Path(rect), with: .color(.cockpit), lineWidth: 2.5)
                    context.stroke(Path(rect), with: .color(.signal), lineWidth: 1)
                    dot(context, cursor, .white, cellW, cellH, 1.2)
                }
            }
            .contentShape(.rect)
            .gesture(SpatialTapGesture().onEnded { tap in
                let x = min(Block.width, max(1, Int(tap.location.x / cellW) + 1))
                let y = min(Block.height, max(1, Int(tap.location.y / cellH) + 1))
                select(Block(x: x, y: y))
            })
        }
        .aspectRatio(2, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 6))
        .accessibilityElement()
        .accessibilityLabel("World map")
        .accessibilityValue("Selected block \(cursor.description)")
    }

    private func point(_ block: Block, _ cellW: CGFloat, _ cellH: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(block.x) - 0.5) * cellW, y: (CGFloat(block.y) - 0.5) * cellH)
    }

    private func dot(_ context: GraphicsContext, _ block: Block, _ color: Color,
                     _ cellW: CGFloat, _ cellH: CGFloat, _ radius: CGFloat) {
        let center = point(block, cellW, cellH)
        let marker = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                             width: radius * 2, height: radius * 2))
        context.fill(marker, with: .color(color))
        context.stroke(marker, with: .color(.cockpit), lineWidth: 1)
    }
}

struct SectorGrid: View {
    let world: World
    let cursor: Block
    let waypoints: Set<Block>
    let select: (Block) -> Void

    var body: some View {
        GeometryReader { area in
            let side = max(0, min(area.size.width, area.size.height) - 16)
            let cell = max(0, side / 9 - 3)
            VStack(spacing: 3) {
                ForEach(-4...4, id: \.self) { dy in
                    HStack(spacing: 3) {
                        ForEach(-4...4, id: \.self) { dx in
                            if (1...Block.height).contains(cursor.y + dy) {
                                let block = cursor.moved(dx: dx, dy: dy)
                                Button { select(block) } label: {
                                    tile(block).frame(width: cell, height: cell)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Block \(block.description), \(status(block))")
                                .help("\(block.description) · \(status(block))")
                            } else {
                                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.08))
                                    .frame(width: cell, height: cell).accessibilityHidden(true)
                            }
                        }
                    }
                }
            }
            .frame(width: area.size.width, height: area.size.height)
        }
        .aspectRatio(2, contentMode: .fit)
        .background(.black.opacity(0.19), in: .rect(cornerRadius: 6))
        .accessibilityLabel("Sector map")
    }

    private func tile(_ block: Block) -> some View {
        let color: Color = block == world.base ? .signal
            : world.occupied.contains(block) ? .terminal
            : world.land[block] != nil ? Color(red: 0.18, green: 0.38, blue: 0.28)
            : Color(red: 0.12, green: 0.23, blue: 0.33)
        return RoundedRectangle(cornerRadius: 3).fill(color)
            .overlay {
                if waypoints.contains(block) { Circle().fill(.white).frame(width: 6, height: 6) }
                if block == cursor { RoundedRectangle(cornerRadius: 3).strokeBorder(.white, lineWidth: 2) }
            }
    }

    private func status(_ block: Block) -> String {
        if block == world.base { return "base" }
        if waypoints.contains(block) { return "waypoint" }
        if world.occupied.contains(block) { return "occupied" }
        return world.land[block] != nil ? "land" : "ocean"
    }
}
