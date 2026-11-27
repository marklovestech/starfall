import Foundation
@testable import StarfallCore
import Testing

@Test func recordedScoreMatchesTurboPascalFileBytes() throws {
    let original = try fixture("product-build/SCORFILE.DAT")
    var hall = try HallOfFame(data: original)
    #expect(hall.data == original)

    let score = 17_513
    #expect(hall.rank(for: score) == 1)
    let recorded = hall.record(name: "devin", world: "VOLTAR", score: score)
    #expect(recorded)

    // First record written by PLAYGAME.COM after quitting Voltar as "devin".
    let dosRecord: [UInt8] = [
        0x05, 0x64, 0x65, 0x76, 0x69, 0x6e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x36, 0x08, 0x4f, 0x08, 0x82, 0x08, 0x20, 0x09, 0x28, 0x09, 0x30, 0x09, 0x82, 0x08, 0x4f, 0x06,
        0x56, 0x4f, 0x4c, 0x54, 0x41, 0x52, 0x82, 0x00, 0xff, 0xff, 0x43, 0x00, 0xff, 0xff, 0xc4, 0x00,
        0x05, 0x73, 0x75, 0x73, 0x61, 0x6e, 0x66, 0x66, 0x84, 0x00, 0x00, 0x00, 0x00, 0xa0, 0x8f, 0x00,
        0x00, 0x00, 0xd2, 0x08,
    ]
    #expect(hall.data == Data(dosRecord) + original.dropLast(68))
    let updated = try HallOfFameEntry.decode(hall.data)
    #expect(updated.first?.name == "devin")
    #expect(updated.first?.world == "VOLTAR")
    #expect(updated.first?.score == 17_513)
    #expect(updated.dropFirst().first?.rank == 2)
}

@Test func scoresUseDOSStringLengthsAndInsertBeforeTies() throws {
    let original = try fixture("product-build/SCORFILE.DAT")
    var hall = try HallOfFame(data: original)
    let unranked = hall.record(name: "Unranked", world: "VOLTAR", score: -1)
    #expect(!unranked)
    #expect(hall.data == original)

    let name = String(repeating: "é", count: 30)
    let world = String(repeating: "Ü", count: 30)
    #expect(hall.rank(for: 0) == 7)
    let recorded = hall.record(name: name + "!", world: world + "!", score: 0)
    #expect(recorded)
    let entries = try HallOfFameEntry.decode(hall.data)
    #expect(entries[6].name == name)
    #expect(entries[6].world == world)
    #expect(entries[6].score == 0)
    #expect(entries[7].name == "Markie")
    #expect(hall.data[6 * 68 + 1] == 0x82)
    #expect(hall.data[(6 * 68 + 62)..<(7 * 68)] == Data(repeating: 0, count: 6))
    #expect(throws: ArchiveError.self) { try HallOfFame(data: hall.data.dropLast()) }
}

@Test func scoreAtTheCutoffReplacesLastPlace() throws {
    let original = try fixture("product-build/SCORFILE.DAT")
    var hall = try HallOfFame(data: original)
    for score in 1...9 {
        let recorded = hall.record(name: "Score \(score)", world: "VOLTAR", score: score)
        #expect(recorded)
    }
    #expect(hall.entries.count == 15)
    #expect(hall.rank(for: 1) == 15)
    let firstFourteen = hall.data.prefix(14 * 68)
    let recorded = hall.record(name: "New last place", world: "VOLTAR", score: 1)
    #expect(recorded)
    #expect(hall.data.prefix(14 * 68) == firstFourteen)
    #expect(hall.entries.last?.name == "New last place")
    #expect(hall.entries.last?.score == 1)
    #expect(hall.rank(for: 0) == nil)
}

@Test func finalScoreCountsNodesInOccupiedBlocksAndBothPendingTrees() throws {
    var world = try voltar()
    let resources = try catalog()
    #expect(world.finalScore(catalog: resources) == 17_514)
    let resource = try #require(resources.resources.first { $0.scoreValue > 0 })
    let stock = Stock(number: resource.id, quantity: 100, flags: 0, contents: [])
    var container = stock
    container.contents = [stock]

    let occupied = try #require(world.occupied.first(where: { world.land[$0] != nil }))
    let unoccupied = try #require(world.land.keys.first(where: { !world.occupied.contains($0) }))
    world.land[occupied]?.stock = [container, stock]
    world.land[unoccupied]?.stock = [stock]
    world.occupied = [occupied]
    var action = try #require(world.pending.first)
    action.equipment = [container]
    action.objects = [stock]
    world.pending = [action]
    world.traderStock = [stock]

    #expect(world.finalScore(catalog: resources) == resource.scoreValue * 6)
}
