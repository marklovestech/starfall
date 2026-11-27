import Foundation

public struct Block: Hashable, Sendable, CustomStringConvertible {
    public static let width = 288
    public static let height = 144
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public var isOnMap: Bool { (1...Self.width).contains(x) && (1...Self.height).contains(y) }
    public var description: String { "\(x), \(y)" }
    public var longitude: String { Self.angle(x - 144, negative: "W", positive: "E") }
    public var latitude: String { Self.angle(y - 72, negative: "N", positive: "S") }

    public func moved(dx: Int, dy: Int) -> Self {
        let wrappedX = ((x - 1 + dx) % Self.width + Self.width) % Self.width + 1
        return Self(x: wrappedX, y: min(Self.height, max(1, y + dy)))
    }

    private static func angle(_ offset: Int, negative: String, positive: String) -> String {
        let minutes = abs(offset) * 75
        let suffix = offset < 0 ? negative : offset > 0 ? positive : ""
        return "\(minutes / 60)° \(minutes % 60)′ \(suffix)"
    }
}

public struct GameTime: Equatable, Sendable, CustomStringConvertible {
    public let day: Int
    public let month: Int
    public let year: Int
    public let second: Int
    public let minute: Int
    public let hour: Int

    public init(day: Int, month: Int, year: Int, second: Int, minute: Int, hour: Int) {
        self.day = day
        self.month = month
        self.year = year
        self.second = second
        self.minute = minute
        self.hour = hour
    }

    public init(seconds: Int) {
        self.init(
            day: seconds / 86_400 % 30, month: seconds / 2_592_000 % 12,
            year: seconds / 31_104_000, second: seconds % 60, minute: seconds / 60 % 60,
            hour: seconds / 3_600 % 24
        )
    }

    public var totalSeconds: Int {
        (((year * 12 + month) * 30 + day) * 24 + hour) * 3_600 + minute * 60 + second
    }

    public var description: String {
        String(format: "%04d.%02d.%02d  %02d:%02d:%02d", year, month + 1, day + 1, hour, minute, second)
    }
}

public struct Stock: Equatable, Sendable {
    struct StackKind: Hashable {
        let number: Int
        let found: Bool
        let extracted: Bool
    }

    public let number: Int
    public var quantity: Double
    public var flags: UInt8
    public var contents: [Stock]
    public var found: Bool { flags & 1 != 0 }
    public var extracted: Bool { flags & 2 != 0 }
    var stackKind: StackKind? {
        found || extracted ? StackKind(number: number, found: found, extracted: extracted) : nil
    }
}

public struct Land: Equatable, Sendable {
    public let climate: UInt8
    public let altitude: Int
    public var stock: [Stock]
    public var altitudeMeters: Int { altitude * 100 }
    public var temperature: Int { Int(climate >> 4) }
    public var moisture: Int { Int(climate & 15) }
}

public enum Action: Int, CaseIterable, Identifiable, Sendable {
    case exploration = 1, extraction, development, refinement, production, transportation
    case traderArrival, traderDeparture

    public var id: Self { self }
    public var title: String {
        switch self {
        case .exploration: "Mineral exploration"
        case .extraction: "Extraction"
        case .development: "Development"
        case .refinement: "Refinement"
        case .production: "Production"
        case .transportation: "Transportation"
        case .traderArrival: "Trader arrival"
        case .traderDeparture: "Trader departure"
        }
    }
}

public struct Waypoint: Equatable, Sendable {
    public let block: Block
    public let distance: Double
}

public enum TransportMode: String, CaseIterable, Sendable {
    case air, land, water
}

public struct Pending: Equatable, Sendable {
    public let block: Block
    public let code: Int
    public let started: GameTime
    public let estimated: GameTime
    public var updatesLeft: Int
    public let speed: Double
    public var distance: Double
    public var equipment: [Stock]
    public var objects: [Stock]
    public var route: [Waypoint]
    var lastLandfall: Block?
    public var action: Action? { Action(rawValue: code) }
    public var title: String { action?.title ?? "Action \(code)" }
}

public struct LogEntry: Equatable, Sendable {
    public let block: Block
    public let description: String
    public let completed: GameTime
}

public struct World: Equatable, Sendable {
    public var name: String
    public let pictureWords: [Int16]
    public var land: [Block: Land]
    public var log: [LogEntry]
    public var pending: [Pending]
    public var occupied: Set<Block>
    public var newPlanet: Bool
    public var base: Block?
    public let temperateLatitude: Int
    public var time: GameTime
    public var timeIncrement: GameTime
    public let updateIncrement: GameTime
    public var timeUntilUpdate: GameTime
    public var cursor: Block
    public var traderInOrbit: Bool
    public var traderCalled: Bool
    public var traderStock: [Stock]
    public var balance: Double
    public var debtLimit: Double

    public var picture: PackedPicture {
        get throws { try PackedPicture(data: pictureWords.flatMap { word in
            let bits = UInt16(bitPattern: word)
            return [UInt8(truncatingIfNeeded: bits), UInt8(bits >> 8)]
        }) }
    }

    public var inventory: [Int: Double] {
        land.values.reduce(into: [:]) { result, block in
            for resource in block.stock where resource.extracted && resource.quantity > 0 {
                result[resource.number, default: 0] += resource.quantity
            }
        }
    }

    public func finalScore(catalog: ResourceCatalog) -> Int {
        func score(_ tree: [Stock]) -> Int {
            // Score the sibling list as if all compatible loose stock had been combined.
            var counted = Set(tree.lazy.filter { !$0.contents.isEmpty }.compactMap(\.stackKind))
            return tree.reduce(0) { total, stock in
                if stock.contents.isEmpty, let kind = stock.stackKind, !counted.insert(kind).inserted {
                    return total
                }
                return total + (catalog[stock.number]?.scoreValue ?? 0) + score(stock.contents)
            }
        }
        var transportEquipment = [Block: [Stock]]()
        var pendingScore = 0
        for item in pending {
            if item.action == .transportation {
                transportEquipment[item.block, default: []].append(contentsOf: item.equipment)
            } else {
                pendingScore += score(item.equipment)
            }
            pendingScore += score(item.objects)
        }
        return occupied.union(transportEquipment.keys).reduce(pendingScore) { total, block in
            let stationary = occupied.contains(block) ? land[block]?.stock ?? [] : []
            return total + score(stationary + (transportEquipment[block] ?? []))
        }
    }
}
