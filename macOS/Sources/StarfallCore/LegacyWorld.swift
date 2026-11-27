import Foundation

public enum LegacyWorld {
    public static func decode(_ data: Data) throws -> World {
        var reader = try PascalText(data)
        let name = try reader.string()
        let words = try (0..<7_000).map { _ in Int16(try reader.integer()) }
        var land = [Block: Land]()
        while true {
            let line = try reader.string()
            if line == "DATAEND" { break }
            guard let x = Int(line), (1...Block.width).contains(x) else { throw reader.error("land block or DATAEND") }
            let block = try Block(x: x, y: reader.integer(1...Block.height))
            guard land[block] == nil else { throw reader.error("unique land block") }
            land[block] = try Land(climate: UInt8(reader.integer(0...255)), altitude: reader.integer(0...240),
                                   stock: reader.stock())
        }
        let log = try reader.list { try LogEntry(block: $0.block(), description: $0.string(), completed: $0.time()) }
        let pending = try reader.list { reader in
            try Pending(block: reader.block(), code: reader.integer(0...255), started: reader.time(),
                        estimated: reader.time(), updatesLeft: reader.integer(), speed: reader.real(),
                        distance: reader.real(), equipment: reader.stock(), objects: reader.stock(),
                        route: reader.list { try Waypoint(block: $0.block(), distance: $0.real()) })
        }
        let occupied = Set(try reader.list { try $0.block() })
        let newPlanet = try reader.boolean()
        let x = try reader.integer()
        let y = try reader.integer()
        let base = Block(x: x, y: y)
        guard base.isOnMap || (x == -1 && y == -1) else { throw reader.error("base coordinates or -1, -1") }
        let world = try World(
            name: name, pictureWords: words, land: land, log: log, pending: pending, occupied: occupied,
            newPlanet: newPlanet, base: base.isOnMap ? base : nil, temperateLatitude: reader.integer(0...144),
            time: reader.time(), timeIncrement: reader.time(), updateIncrement: reader.time(),
            timeUntilUpdate: reader.time(), cursor: reader.block(), traderInOrbit: reader.boolean(),
            traderCalled: reader.boolean(), traderStock: reader.stock(), balance: reader.real(), debtLimit: reader.real()
        )
        guard reader.atEnd else { throw reader.error("end of world file") }
        let picture = try world.picture
        guard picture.width >= Block.width + 7, picture.height >= Block.height + 7 else {
            throw ArchiveError.binary("world picture is too small")
        }
        return world
    }

    public static func encode(_ world: World) -> Data {
        var writer = WorldWriter()
        writer.line(world.name)
        for word in world.pictureWords { writer.line(word) }
        for block in world.land.keys.sorted(by: WorldWriter.blockOrder) {
            guard let land = world.land[block] else { continue }
            writer.block(block)
            writer.line(land.climate)
            writer.line(land.altitude)
            writer.stock(land.stock)
        }
        writer.line("DATAEND")
        for entry in world.log {
            writer.line("DATA")
            writer.block(entry.block)
            writer.line(entry.description)
            writer.time(entry.completed)
        }
        writer.line("NIL")
        for item in world.pending {
            writer.line("DATA")
            writer.block(item.block)
            writer.line(item.code)
            writer.time(item.started)
            writer.time(item.estimated)
            writer.line(item.updatesLeft)
            writer.line(item.speed)
            writer.line(item.distance)
            writer.stock(item.equipment)
            writer.stock(item.objects)
            for waypoint in item.route {
                writer.line("DATA")
                writer.block(waypoint.block)
                writer.line(waypoint.distance)
            }
            writer.line("NIL")
        }
        writer.line("NIL")
        for block in world.occupied.sorted(by: WorldWriter.blockOrder) {
            writer.line("DATA")
            writer.block(block)
        }
        writer.line("NIL")
        writer.boolean(world.newPlanet)
        writer.block(world.base ?? Block(x: -1, y: -1))
        writer.line(world.temperateLatitude)
        writer.time(world.time)
        writer.time(world.timeIncrement)
        writer.time(world.updateIncrement)
        writer.time(world.timeUntilUpdate)
        writer.block(world.cursor)
        writer.boolean(world.traderInOrbit)
        writer.boolean(world.traderCalled)
        writer.stock(world.traderStock)
        writer.line(world.balance)
        writer.line(world.debtLimit)
        return writer.data
    }
}

private struct WorldWriter {
    var lines = [String]()
    var data: Data { Data((lines.joined(separator: "\r\n") + "\r\n").utf8) }

    mutating func line(_ value: some CustomStringConvertible) { lines.append(value.description) }
    mutating func boolean(_ value: Bool) { line(value ? "T" : "F") }

    mutating func block(_ value: Block) {
        line(value.x)
        line(value.y)
    }

    mutating func time(_ value: GameTime) {
        for unit in [value.day, value.month, value.year, value.second, value.minute, value.hour] { line(unit) }
    }

    mutating func stock(_ items: [Stock]) {
        for item in items {
            line("DATA")
            line(item.number)
            line(item.quantity)
            line(item.flags)
        }
        line("NIL")
        for item in items.reversed() { stock(item.contents) }
    }

    static func blockOrder(_ lhs: Block, _ rhs: Block) -> Bool { (lhs.x, lhs.y) < (rhs.x, rhs.y) }
}
