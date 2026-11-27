import Foundation
import StarfallCore
import Testing

private let orig1986 = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("orig1986")

func fixture(_ path: String) throws -> Data {
    try Data(contentsOf: orig1986.appendingPathComponent(path))
}

func voltar() throws -> World {
    try LegacyWorld.decode(fixture("product-build/VOLTAR.DAT"))
}

func catalog() throws -> ResourceCatalog {
    try ResourceCatalog(data: fixture("product-build/RESOURCE.DAT"))
}

@Test func originalVoltarDecodes() throws {
    let world = try voltar()
    #expect(world.name == "VOLTAR")
    #expect(world.land.count == 7_218)
    #expect(world.base == Block(x: 198, y: 111))
    #expect(world.cursor == Block(x: 197, y: 110))
    #expect(world.time == GameTime(day: 20, month: 8, year: 2243, second: 28, minute: 20, hour: 6))
    #expect(world.balance == -3_348_006.5499)
    #expect(world.pending.count == 1)
    #expect(world.pending.first?.action == .exploration)
    #expect(world.pending.first?.updatesLeft == 24)
    #expect(world.log.first?.description == "MINERAL EXPLORATION")
}

@Test func worldCanRoundTripPascalSaves() throws {
    var world = try voltar()
    world.cursor = world.cursor.moved(dx: -5, dy: 5)
    world.balance += 100
    let encoded = LegacyWorld.encode(world)
    #expect(try LegacyWorld.decode(encoded) == world)
    #expect(throws: ArchiveError.self) { try LegacyWorld.decode(Data(encoded.dropLast(20))) }
}

@Test func accentedDOSWorldNamesRoundTripAsCodePage437() throws {
    let title = Data([0x43, 0x41, 0x46, 0x90, 0x0D, 0x0A])
    let original = try fixture("product-build/VOLTAR.DAT")
    let dosSave = title + original.dropFirst("VOLTAR\r\n".utf8.count)
    let world = try LegacyWorld.decode(dosSave)
    #expect(world.name == "CAFÉ")
    let encoded = LegacyWorld.encode(world)
    #expect(encoded.prefix(title.count) == title)
    #expect(try LegacyWorld.decode(encoded) == world)
}

@Test func pictureMatchesOriginalLandMatrix() throws {
    let world = try voltar()
    let picture = try world.picture
    #expect(picture.width == 303)
    #expect(picture.height == 158)
    let agreement = world.land.keys.filter { picture[$0.x + 6, $0.y + 7] == 0 }
    #expect(agreement.count == world.land.count)
    #expect(picture[7, 8] == 1)
    let title = try PackedPicture(data: Array(fixture("product-build/STARFALL.PIC")))
    #expect(title.width == 320)
    #expect(title.height == 200)
    #expect(Set(title.pixels).count == 4)
}

@Test func archivedHelpScoresAndResourcesDecode() throws {
    let topics = try HelpTopic.decode(index: fixture("HELPINDX.DAT"), pages: fixture("HELPFILE.DAT"))
    #expect(topics.count == 24)
    #expect(topics.first?.title == "Introduction to STARFALL")
    #expect(topics.first?.pages.count == 19)
    #expect(topics.first?.pages.first?.contains("PLAY OF THE GAME") == true)
    let scores = try HallOfFameEntry.decode(fixture("product-build/SCORFILE.DAT"))
    #expect(scores.first?.name == "David Coleman - Ace")
    #expect(scores.first?.world == "NEW EDEN")
    #expect(scores.first?.score == 5_439)
    let resources = try catalog()
    #expect(resources.resources.count == 255)
    #expect(resources[1]?.name == "ICE")
    #expect(resources[1]?.units == "hectares")
    #expect(resources[0] == nil)
}

@Test func movementWrapsLongitudeAndClampsLatitude() {
    let corner = Block(x: 1, y: 1)
    #expect(corner.moved(dx: -1, dy: -1) == Block(x: 288, y: 1))
    #expect(corner.moved(dx: -8, dy: 8) == Block(x: 281, y: 9))
    #expect(Block(x: 148, y: 68).latitude == "5° 0′ N")
    #expect(Block(x: 148, y: 68).longitude == "5° 0′ E")
}
