import Foundation
@testable import StarfallCore
import Testing

@Test func renderedWorldPictureMatchesVoltarPixelForPixel() throws {
    let world = try voltar()
    let rendered = World.renderPictureWords(land: Set(world.land.keys))
    let renderedBytes = rendered.flatMap { word -> [UInt8] in
        let bits = UInt16(bitPattern: word)
        return [UInt8(truncatingIfNeeded: bits), UInt8(bits >> 8)]
    }
    #expect(try PackedPicture(data: renderedBytes) == world.picture)
}

@Test func generatedWorldMatchesPascalBoundsAndRoundTrips() throws {
    let resources = try catalog()
    var random = GeneratorRandom(state: 42)
    let world = World.generate(named: "  KEPLER\n", catalog: resources, using: &random)

    #expect(world.name == "KEPLER")
    #expect(world.pictureWords.count == 7_000)
    #expect(world.land.count >= 4_147)
    #expect(world.land.count <= 10_000)
    #expect(world.newPlanet)
    #expect(world.base == nil)
    #expect(world.cursor == Block(x: 144, y: 72))
    #expect((0...90).contains(world.temperateLatitude))
    #expect((2050...2299).contains(world.time.year))
    #expect((0..<12).contains(world.time.month))
    #expect((0..<30).contains(world.time.day))
    #expect(world.timeIncrement == GameTime(day: 0, month: 0, year: 0, second: 0, minute: 6, hour: 0))
    #expect(world.updateIncrement == GameTime(day: 0, month: 0, year: 0, second: 0, minute: 0, hour: 8))
    #expect(world.timeUntilUpdate == GameTime(day: 0, month: 0, year: 0, second: 0, minute: 0, hour: 0))
    #expect(world.balance == 0)
    #expect(world.debtLimit == -5_950_000)
    #expect(!world.traderInOrbit)
    #expect(!world.traderCalled)
    #expect(world.log.isEmpty)
    #expect(world.pending.isEmpty)
    #expect(world.occupied.isEmpty)

    let picture = try world.picture
    #expect(picture.width == 303)
    #expect(picture.height == 158)
    for y in 1...Block.height {
        for x in 1...Block.width {
            let block = Block(x: x, y: y)
            let expected: UInt8 = world.land[block] != nil ? 0 : 1
            #expect(picture[x + 6, y + 7] == expected)
        }
    }

    var depositCount = 0
    for land in world.land.values {
        #expect((1...240).contains(land.altitude))
        #expect((0...15).contains(land.temperature))
        #expect((0...15).contains(land.moisture))
        for item in land.stock {
            depositCount += 1
            let resource = try #require(resources[item.number])
            #expect(resource.naturallyOccurring)
            #expect(resource.subsurface)
            #expect(!item.found)
            #expect(!item.extracted)
            #expect(item.quantity > 0)
        }
    }
    #expect(depositCount >= 1_000)
    #expect(try LegacyWorld.decode(LegacyWorld.encode(world)) == world)
}

@Test func worldNameSanitizationEnforcesDOSLimits() {
    #expect(World.sanitizeName("") == "NEW EDEN")
    #expect(World.sanitizeName("   \t\n ") == "NEW EDEN")
    #expect(World.sanitizeName("ALPHA\r\nCENTAURI") == "ALPHACENTAURI")
    #expect(World.sanitizeName(String(repeating: "A", count: 40)).count == 30)
}

@Test func generatedWorldPlaysThroughBaseTradeAndClock() throws {
    let resources = try catalog()
    var random = GeneratorRandom(state: 99)
    var world = World.generate(named: "AURORA", catalog: resources, using: &random)
    let landingSite = try #require(world.land.first(where: { !$0.value.stock.isEmpty })?.key)

    try world.setBase(at: landingSite, catalog: resources, using: &random)
    #expect(world.base == landingSite)
    #expect(world.traderInOrbit)
    #expect(world.pending.contains { $0.action == .traderDeparture })

    let offer = try #require(world.traderStock.first(where: {
        $0.quantity >= 1 && (resources[$0.number]?.baseCost ?? 0) > 0
            && (resources[$0.number]?.purchasePrice ?? .infinity) < world.balance - world.debtLimit
    }))
    try world.trade(resource: offer.number, quantity: 1, buying: true, catalog: resources)
    #expect(world.balance < 0)
    #expect(world.occupied.contains(landingSite))

    world.advanceToNextUpdate(catalog: resources, using: &random)
    #expect(try LegacyWorld.decode(LegacyWorld.encode(world)) == world)
}

private struct GeneratorRandom: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
