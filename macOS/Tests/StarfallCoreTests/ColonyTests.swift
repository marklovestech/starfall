@testable import StarfallCore
import Testing

@Test func traderCyclePreservesTheColonyState() throws {
    var world = try voltar()
    let resources = try catalog()
    let originalBalance = world.balance
    var random = SeededRandom()
    try world.callTrader(using: &random)
    #expect(world.traderCalled)
    #expect(world.balance == originalBalance - World.traderCallCost)
    #expect(throws: ColonyError.self) { try world.callTrader(using: &random) }

    let count = try #require(world.pending.first(where: { $0.action == .traderArrival })).updatesLeft
    for _ in 0..<count {
        world.advanceToNextUpdate(catalog: resources, using: &random)
    }
    #expect(world.traderInOrbit)
    #expect(!world.traderCalled)
    #expect(world.log.last?.description == "TRADER ARRIVED")
    let stock = try #require(world.traderStock.first(where: {
        $0.quantity >= 1 && (resources[$0.number]?.baseCost ?? 0) > 0
            && (resources[$0.number]?.purchasePrice ?? .infinity) < world.balance - world.debtLimit
    }))
    let resource = try #require(resources[stock.number])
    let beforePurchase = world.balance
    try world.trade(resource: stock.number, quantity: 1, buying: true, catalog: resources)
    #expect(world.traderStock.first { $0.number == stock.number }?.quantity == stock.quantity - 1)
    #expect(world.balance == beforePurchase - resource.purchasePrice)
    try world.trade(resource: stock.number, quantity: 1, buying: false, catalog: resources)
    #expect(world.traderStock.first { $0.number == stock.number }?.quantity == stock.quantity)
    #expect(world.balance == beforePurchase - resource.purchasePrice + resource.salePrice)
    #expect(throws: ColonyError.self) {
        try world.trade(resource: stock.number, quantity: .nan, buying: true, catalog: resources)
    }
    #expect(try LegacyWorld.decode(LegacyWorld.encode(world)) == world)

    let stay = try #require(world.pending.first(where: { $0.action == .traderDeparture })).updatesLeft
    for _ in 0..<max(1, stay) {
        world.advanceToNextUpdate(catalog: resources, using: &random)
    }
    #expect(!world.traderInOrbit)
    #expect(world.traderStock.isEmpty)
    #expect(world.log.last?.description == "TRADER LEFT")
}

@Test func firstBaseImmediatelyReceivesInterstellarLiner() throws {
    var world = try voltar()
    let resources = try catalog()
    let block = try #require(world.base)
    var random = SeededRandom()
    world.base = nil
    world.newPlanet = true
    #expect(throws: ColonyError.self) {
        try world.setBase(at: Block(x: 1, y: 1), catalog: resources, using: &random)
    }
    try world.setBase(at: block, catalog: resources, using: &random)
    #expect(world.base == block)
    #expect(world.traderInOrbit)
    #expect(world.pending.contains { $0.action == .traderDeparture })
}

@Test func archivedPendingActionsContinueOnNativeClock() throws {
    var world = try voltar()
    let resources = try catalog()
    var random = SeededRandom()
    let earlier = world.time.totalSeconds
    let entries = world.log.count
    for _ in 0..<27 { world.advanceToNextUpdate(catalog: resources, using: &random) }
    #expect(world.time.totalSeconds > earlier)
    #expect(world.log.count > entries)
    #expect(try LegacyWorld.decode(LegacyWorld.encode(world)) == world)
}

@Test func extractionReservesEquipmentAndReturnsMaterial() throws {
    let resources = try catalog()
    var world = try voltar()
    let block = try #require(world.base)
    let material = try #require(resources.resources.first { $0.extractable && $0.extractionSpeed > 0 })
    let tool = try #require(resources.resources.first { $0.extracts && $0.extractionSpeed > 0 })
    world.pending = []
    world.land[block]?.stock = [
        Stock(number: material.id, quantity: 2, flags: 1, contents: []),
        Stock(number: tool.id, quantity: 100, flags: 3, contents: (tool.basic + tool.active).map {
            Stock(number: $0.number, quantity: 100_000, flags: 3, contents: [])
        }),
    ]
    try world.process(.extraction, at: block, objectIndex: 0, equipmentIndex: 1, quantity: 1, catalog: resources)
    #expect(world.pending.first?.action == .extraction)
    #expect(world.land[block]?.stock.map(\.quantity) == [1])
    var random = SeededRandom()
    for _ in 0..<max(1, world.pending[0].updatesLeft) {
        world.advanceToNextUpdate(catalog: resources, using: &random)
    }
    #expect(world.pending.isEmpty)
    #expect(world.land[block]?.stock.contains { $0.number == material.id && $0.extracted && $0.quantity == 1 } == true)
    #expect(world.land[block]?.stock.contains { $0.number == tool.id } == true)
}

@Test func shipTransportsEquipmentAndLinkedSupplies() throws {
    var world = try voltar()
    let resources = try catalog()
    let origin = try #require(world.base)
    let destination = origin.moved(dx: 1, dy: 0)
    let tool = try #require(resources.resources.first {
        $0.transports && $0.movable && $0.airSpeed > 0 && $0.basic.isEmpty && $0.active.isEmpty && $0.cargoCapacity > 0
    })
    let cargo = try #require(resources.resources.first {
        $0.movable && $0.id != tool.id && $0.weight <= tool.cargoCapacity && $0.basic.isEmpty
    })
    let vehicle = Stock(number: tool.id, quantity: 1, flags: 3, contents: [])
    let supply = Stock(number: cargo.id, quantity: 1, flags: 3, contents: [])
    world.land[origin]?.stock = [vehicle, supply]
    world.land[destination] = Land(climate: 0, altitude: 1, stock: [])
    world.pending = []
    try world.linkSupply(at: origin, equipmentIndex: 0, supplyIndex: 1, quantity: 1, catalog: resources)
    try world.transport(from: origin, to: destination, vehicleIndex: 0, mode: .air, catalog: resources)
    #expect(world.land[origin]?.stock.isEmpty == true)
    #expect(world.pending.first?.route.last?.block == destination)
    #expect(try LegacyWorld.decode(LegacyWorld.encode(world)) == world)
    var random = SeededRandom()
    for _ in 0..<max(1, world.pending[0].updatesLeft) {
        world.advanceToNextUpdate(catalog: resources, using: &random)
    }
    #expect(world.pending.isEmpty)
    #expect(world.land[destination]?.stock.first?.contents == [supply])
    try world.unlinkSupply(at: destination, equipmentIndex: 0, supplyIndex: 0, catalog: resources)
    #expect(world.land[destination]?.stock == [vehicle, supply])
}

@Test func productionConsumesExpendableInputsAndReturnsReusableInputs() throws {
    var world = try voltar()
    let resources = try catalog()
    let block = try #require(world.base)
    let product = try #require(resources.resources.first { $0.name == "FOOD" })
    let inputs = preparedProductionStock(product.recipe, quantity: 2, catalog: resources)
    #expect(inputs.contains { resources[$0.number]?.expendable == true })
    #expect(inputs.contains { resources[$0.number]?.expendable == false })
    world.land[block]?.stock = inputs
    world.pending = []
    try world.produce(product.id, at: block, quantity: 2, catalog: resources)
    #expect(world.land[block]?.stock.isEmpty == true)
    #expect(world.pending.first?.action == .production)
    var random = SeededRandom()
    for _ in 0..<max(1, world.pending[0].updatesLeft) {
        world.advanceToNextUpdate(catalog: resources, using: &random)
    }
    #expect(world.land[block]?.stock.first == Stock(number: product.id, quantity: 2, flags: 3, contents: []))
    let stock = try #require(world.land[block]?.stock)
    for input in inputs {
        let leftover = stock.filter { $0.number == input.number }.reduce(0) { $0 + $1.quantity }
        #expect(leftover == (resources[input.number]?.expendable == true ? 0 : input.quantity))
    }
}

private func preparedProductionStock(_ recipe: [Resource.Ingredient], quantity: Double,
                                     catalog: ResourceCatalog) -> [Stock] {
    recipe.map { choice in
        let resource = catalog[choice.number]
        return Stock(number: choice.number, quantity: choice.quantity * quantity, flags: 3,
                     contents: ((resource?.basic ?? []) + (resource?.active ?? [])).map {
                         Stock(number: $0.number, quantity: 1e15, flags: 3, contents: [])
                     })
    }
}

private struct SeededRandom: RandomNumberGenerator {
    var state: UInt64 = 11

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
