import Foundation

public extension World {
    static let defaultName = "NEW EDEN"
    static let maxNameLength = 30
    static let initialDebtLimit = -5_950_000.0

    static func generate(named name: String = defaultName, catalog: ResourceCatalog) -> World {
        var random = SystemRandomNumberGenerator()
        return generate(named: name, catalog: catalog, using: &random)
    }

    static func generate(named rawName: String = defaultName, catalog: ResourceCatalog,
                         using random: inout some RandomNumberGenerator) -> World {
        let name = sanitizeName(rawName)
        let time = GameTime(
            day: Int.random(in: 0..<30, using: &random),
            month: Int.random(in: 0..<12, using: &random),
            year: 2050 + Int.random(in: 0..<250, using: &random),
            second: Int.random(in: 0..<60, using: &random),
            minute: Int.random(in: 0..<60, using: &random),
            hour: Int.random(in: 0..<24, using: &random)
        )
        let temperateLatitude = (0..<10).reduce(0) { sum, _ in sum + Int.random(in: 0..<10, using: &random) }

        var generator = WorldBuilder(temperateLatitude: temperateLatitude)
        generator.buildLandMasses(using: &random)
        let pictureWords = renderPictureWords(land: generator.landBlocks)
        generator.buildBaseHydroAndTemp()
        generator.buildAltitudes(using: &random)
        let land = generator.allocateSubsurfaceResources(catalog: catalog, using: &random)

        return World(
            name: name,
            pictureWords: pictureWords,
            land: land,
            log: [],
            pending: [],
            occupied: [],
            newPlanet: true,
            base: nil,
            temperateLatitude: temperateLatitude,
            time: time,
            timeIncrement: GameTime(day: 0, month: 0, year: 0, second: 0, minute: 6, hour: 0),
            updateIncrement: GameTime(day: 0, month: 0, year: 0, second: 0, minute: 0, hour: 8),
            timeUntilUpdate: GameTime(day: 0, month: 0, year: 0, second: 0, minute: 0, hour: 0),
            cursor: Block(x: Block.width / 2, y: Block.height / 2),
            traderInOrbit: false,
            traderCalled: false,
            traderStock: [],
            balance: 0,
            debtLimit: initialDebtLimit
        )
    }

    static func sanitizeName(_ rawName: String) -> String {
        let cleaned = rawName
            .unicodeScalars
            .filter { $0.value >= 32 && $0.value != 127 }
        let trimmed = String(String.UnicodeScalarView(cleaned)).trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return defaultName }
        return String(trimmed.prefix(maxNameLength))
    }

    static func renderPictureWords(land: Set<Block>) -> [Int16] {
        let width = 303
        let height = 158
        var pixels = [UInt8](repeating: 2, count: width * height)
        for x in 0..<width { pixels[x] = 0 }

        for loop in 1...37 {
            let x = loop * 8 - 2
            for y in 1...6 { pixels[y * width + x] = 3 }
            for y in 152...157 { pixels[y * width + x] = 3 }
        }
        for loop in 1...19 {
            let y = loop * 8 - 1
            for x in 0...5 { pixels[y * width + x] = 3 }
            for x in 295...300 { pixels[y * width + x] = 3 }
        }
        for x in 6...295 {
            pixels[7 * width + x] = 3
            pixels[152 * width + x] = 3
        }
        for y in 7...152 {
            pixels[y * width + 6] = 3
            pixels[y * width + 295] = 3
        }
        for y in 1...Block.height {
            let rowOffset = (y + 7) * width + 6
            for x in 1...Block.width {
                pixels[rowOffset + x] = land.contains(Block(x: x, y: y)) ? 0 : 1
            }
        }
        return PackedPicture(width: width, height: height, pixels: pixels).encodeWords(count: 7_000)
    }
}

private struct WorldBuilder {
    private static let temperatureGradientFactor = 10
    private static let baseLandPercentage = 10
    private static let modifierLandPercentage = 10
    private static let baseContinentPercentage = 25
    private static let modifierContinentPercentage = 10
    private static let baseMineralPercentage = 35
    private static let modifierMineralPercentage = 20
    private static let maxAltitude = 240

    private static let waterColor: UInt8 = 1
    private static let landColor: UInt8 = 0
    private static let altitudeDoneColor: UInt8 = 2

    let temperateLatitude: Int
    private var colors = [UInt8](repeating: waterColor, count: Block.width * Block.height)
    private var isLand = [Bool](repeating: false, count: Block.width * Block.height)
    private var climates = [UInt8](repeating: 0, count: Block.width * Block.height)
    private var altitudes = [Int](repeating: 0, count: Block.width * Block.height)
    private var landList = [Block]()

    var landBlocks: Set<Block> { Set(landList) }

    init(temperateLatitude: Int) {
        self.temperateLatitude = temperateLatitude
    }

    private func index(_ x: Int, _ y: Int) -> Int {
        (y - 1) * Block.width + (x - 1)
    }

    mutating func buildLandMasses(using random: inout some RandomNumberGenerator) {
        let landPercentage = Double(Self.baseLandPercentage + Int.random(in: 0..<Self.modifierLandPercentage, using: &random)) / 100.0
        let totalLandArea = Int(landPercentage * Double(Block.width * Block.height))
        var remainingLand = totalLandArea

        while remainingLand > 0 {
            let continentPct = Double(Self.baseContinentPercentage + Int.random(in: 0..<Self.modifierContinentPercentage, using: &random)) / 100.0
            let continentArea = Int(continentPct * Double(totalLandArea))
            let continentRadius = Int(Double(continentArea).squareRoot())
            var areaUsed = 0
            var areaLeft = continentArea

            let startX = Int.random(in: 1...Block.width, using: &random)
            let startY = Int.random(in: 1...Block.height, using: &random)
            growContinent(atX: startX, atY: startY, level: 0, radius: continentRadius,
                          areaUsed: &areaUsed, areaLeft: &areaLeft, using: &random)
            remainingLand -= areaUsed
        }
        // MAKEWRLD prepends each land chunk to land_list_root, so reverse for matching traversal order.
        landList.reverse()
    }

    private mutating func growContinent(atX rawX: Int, atY y: Int, level: Int, radius: Int,
                                        areaUsed: inout Int, areaLeft: inout Int,
                                        using random: inout some RandomNumberGenerator) {
        let x = rawX < 1 ? Block.width : (rawX > Block.width ? 1 : rawX)
        guard y >= 1, y <= Block.height, areaLeft > 0 else { return }
        guard Double(radius) * 1.5 > Double(level - Int.random(in: 0..<15, using: &random)) else { return }

        let idx = index(x, y)
        guard !isLand[idx] else { return }

        areaLeft -= 1
        areaUsed += 1
        isLand[idx] = true
        colors[idx] = Self.landColor
        landList.append(Block(x: x, y: y))

        var directions = [0, 1, 2, 3]
        for i in 0..<4 {
            let j = Int.random(in: i..<4, using: &random)
            directions.swapAt(i, j)
        }
        for dir in directions {
            if areaLeft < 0 { break }
            switch dir {
            case 0: growContinent(atX: x, atY: y - 1, level: level + 1, radius: radius, areaUsed: &areaUsed, areaLeft: &areaLeft, using: &random)
            case 1: growContinent(atX: x, atY: y + 1, level: level + 1, radius: radius, areaUsed: &areaUsed, areaLeft: &areaLeft, using: &random)
            case 2: growContinent(atX: x + 1, atY: y, level: level + 1, radius: radius, areaUsed: &areaUsed, areaLeft: &areaLeft, using: &random)
            default: growContinent(atX: x - 1, atY: y, level: level + 1, radius: radius, areaUsed: &areaUsed, areaLeft: &areaLeft, using: &random)
            }
        }
    }

    mutating func buildBaseHydroAndTemp() {
        for sectorX in 0..<36 {
            for sectorY in 0..<18 {
                var waterCount = 0
                for bx in 1...8 {
                    for by in 1...8 {
                        if !isLand[index(sectorX * 8 + bx, sectorY * 8 + by)] {
                            waterCount += 1
                        }
                    }
                }
                let sectorResult = Int(100.0 * (Double(waterCount) / 64.0))
                guard sectorResult != 100 else { continue }
                let baseMoisture = min(15, max(0, Int((Double(sectorResult) / 100.0) * 16.0) + 4))
                for bx in 1...8 {
                    let x = sectorX * 8 + bx
                    for by in 1...8 {
                        let y = sectorY * 8 + by
                        let idx = index(x, y)
                        guard isLand[idx] else { continue }
                        let latitude = Int(Double(abs(y - Block.height / 2)) / Double(Block.height / 2) * 90.0)
                        let baseTemp = min(15, max(0, 8 + (temperateLatitude - latitude) / Self.temperatureGradientFactor))
                        climates[idx] = UInt8((baseTemp << 4) | baseMoisture)
                    }
                }
            }
        }
    }

    mutating func buildAltitudes(using random: inout some RandomNumberGenerator) {
        for block in landList {
            if colorAdjacency(block.x, block.y, color: Self.waterColor) > 0 {
                let idx = index(block.x, block.y)
                altitudes[idx] = Int.random(in: 0..<2, using: &random) + 1
                refineClimate(at: block, using: &random)
                colors[idx] = Self.altitudeDoneColor
            }
        }

        while true {
            var nothingChanged = true
            var anyCandidate = false
            for block in landList {
                let idx = index(block.x, block.y)
                guard altitudes[idx] == 0 else { continue }
                nothingChanged = false
                let redAdjacent = colorAdjacency(block.x, block.y, color: Self.altitudeDoneColor)
                if redAdjacent > 0 { anyCandidate = true }
                if redAdjacent > Int.random(in: 0..<5, using: &random) {
                    colors[idx] = Self.altitudeDoneColor
                    var tempAltitude = (Int.random(in: 0..<6, using: &random) - 1) + averageAltitudeAround(block.x, block.y)
                    if tempAltitude < 1 {
                        tempAltitude = Int.random(in: 0..<2, using: &random) + 1
                    }
                    if tempAltitude > Self.maxAltitude {
                        tempAltitude = Self.maxAltitude
                    }
                    altitudes[idx] = tempAltitude
                    refineClimate(at: block, using: &random)
                }
            }
            if nothingChanged { break }
            if !anyCandidate {
                for block in landList {
                    let idx = index(block.x, block.y)
                    if altitudes[idx] == 0 {
                        altitudes[idx] = Int.random(in: 0..<2, using: &random) + 1
                        refineClimate(at: block, using: &random)
                        colors[idx] = Self.altitudeDoneColor
                    }
                }
                break
            }
        }
    }

    func allocateSubsurfaceResources(catalog: ResourceCatalog,
                                     using random: inout some RandomNumberGenerator) -> [Block: Land] {
        var stocks = [Int: [Stock]]()
        let hasNaturalResource = catalog.resources.contains { $0.naturallyOccurring && $0.likelihoodOfOccurrence > 0 }
        if hasNaturalResource && !landList.isEmpty {
            let mineralPct = Double(Self.baseMineralPercentage + Int.random(in: 0..<Self.modifierMineralPercentage, using: &random))
                - Double(Self.modifierMineralPercentage) / 2.0
            let deposits = Int((Double(Self.baseLandPercentage) / 100.0) * Double(Block.height * Block.width) * mineralPct / 100.0)

            for _ in 0..<deposits {
                var chosen: Resource
                repeat {
                    chosen = catalog.resources[Int.random(in: 0..<catalog.resources.count, using: &random)]
                } while !(chosen.naturallyOccurring && Double(Int.random(in: 0..<100, using: &random)) < chosen.likelihoodOfOccurrence)

                let block = landList[Int.random(in: 0..<landList.count, using: &random)]
                let idx = index(block.x, block.y)
                let amount = chosen.typicalDepositSize * Double(100 + Int.random(in: 0..<150, using: &random) - 75) / 100.0
                let flags: UInt8 = chosen.subsurface ? 0 : 3
                stocks[idx, default: []].insert(Stock(number: chosen.id, quantity: amount, flags: flags, contents: []), at: 0)
            }
        }

        var land = [Block: Land](minimumCapacity: landList.count)
        for block in landList {
            let idx = index(block.x, block.y)
            land[block] = Land(climate: climates[idx], altitude: altitudes[idx], stock: stocks[idx] ?? [])
        }
        return land
    }

    private func colorAdjacency(_ x: Int, _ y: Int, color: UInt8) -> Int {
        var count = 0
        if x > 1 && colors[index(x - 1, y)] == color { count += 1 }
        if x < Block.width && colors[index(x + 1, y)] == color { count += 1 }
        if y > 1 && colors[index(x, y - 1)] == color { count += 1 }
        if y < Block.height && colors[index(x, y + 1)] == color { count += 1 }
        return count
    }

    private func averageAltitudeAround(_ x: Int, _ y: Int) -> Int {
        var count = 0
        var total = 0
        let westX = x <= 1 ? Block.width : x - 1
        let eastX = x >= Block.width ? 1 : x + 1
        let westAlt = altitudes[index(westX, y)]
        if westAlt > 0 { count += 1; total += westAlt }
        let eastAlt = altitudes[index(eastX, y)]
        if eastAlt > 0 { count += 1; total += eastAlt }
        if y > 1 {
            let northAlt = altitudes[index(x, y - 1)]
            if northAlt > 0 { count += 1; total += northAlt }
        }
        if y < Block.height {
            let southAlt = altitudes[index(x, y + 1)]
            if southAlt > 0 { count += 1; total += southAlt }
        }
        return count > 0 ? total / count : 1
    }

    private mutating func refineClimate(at block: Block, using random: inout some RandomNumberGenerator) {
        let idx = index(block.x, block.y)
        let currentMoisture = Int(climates[idx] & 15)
        let waterAdj = colorAdjacency(block.x, block.y, color: Self.waterColor)
        let moisture = min(15, max(0, currentMoisture + (waterAdj - 1) + (Int.random(in: 0..<3, using: &random) - 1)))

        let currentTemp = Int(climates[idx] >> 4)
        let temp = min(15, max(0, currentTemp - (altitudes[idx] - 1) / 30 + Int.random(in: 0..<2, using: &random)))

        climates[idx] = UInt8((temp << 4) | moisture)
    }
}
