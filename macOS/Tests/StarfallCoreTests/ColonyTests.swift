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

@Test func linkingPartOfAProvisionedStackMovesItsShareOfSupplies() throws {
    var world = try voltar()
    let resources = try catalog()
    let block = try #require(world.base)
    let food = try #require(resources.resources.first { $0.name == "FOOD" })
    let people = try #require(resources.resources.first { $0.name == "PEOPLE" })
    let combine = try #require(resources.resources.first { $0.name == "LARGE COMBINE" })
    let provisions = Stock(number: food.id, quantity: 8, flags: 3, contents: [])
    let workers = Stock(number: people.id, quantity: 22, flags: 3, contents: [provisions])
    let equipment = Stock(number: combine.id, quantity: 1, flags: 3, contents: [])
    world.land[block]?.stock = [workers, equipment]
    try world.linkSupply(at: block, equipmentIndex: 1, supplyIndex: 0, quantity: 15, catalog: resources)
    let stocks = try #require(world.land[block]?.stock)
    #expect(stocks[0].quantity == 7)
    let linked = try #require(stocks[1].contents.first)
    #expect(linked.quantity == 15)
    let linkedFood = try #require(linked.contents.first)
    let remainingFood = try #require(stocks[0].contents.first)
    #expect(linkedFood.quantity == 8 * (15.0 / 22.0))
    #expect(linkedFood.quantity + remainingFood.quantity == 8)
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
    var plan = try world.planTransport(from: origin, vehicleIndex: 0, mode: .air, catalog: resources)
    try world.plotWaypoint(destination, in: &plan, catalog: resources)
    try world.transport(plan, catalog: resources)
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

@Test func transportFollowsPlottedWaypointsAndArrivesOnTheScheduledUpdate() throws {
    var world = try voltar()
    let resources = try catalog()
    let vehicle = try #require(resources.resources.first {
        $0.transports && $0.movable && $0.airSpeed > 0 && $0.basic.isEmpty && $0.active.isEmpty
    })
    let stock = Stock(number: vehicle.id, quantity: 1, flags: 3, contents: [])
    let origin = Block(x: 1, y: 36)
    let west = Block(x: Block.width, y: 36)
    let northwest = west.moved(dx: 0, dy: -1)
    let destination = origin.moved(dx: 0, dy: -1)
    world.land[origin] = Land(climate: 0, altitude: 1, stock: [stock])
    world.land[west] = nil
    world.land[northwest] = nil
    world.land[destination] = Land(climate: 0, altitude: 1, stock: [])
    world.pending = []
    let before = world

    var plan = try world.planTransport(from: origin, vehicleIndex: 0, mode: .air, catalog: resources)
    #expect(throws: ColonyError.invalidWaypoint) {
        try world.plotWaypoint(northwest, in: &plan, catalog: resources)
    }
    try world.plotWaypoint(west, in: &plan, catalog: resources)
    #expect(plan.distance == 38_500.0 / 288 / 2)
    try world.plotWaypoint(origin, in: &plan, catalog: resources)
    #expect(plan.route.isEmpty && plan.distance == 0)
    try world.plotWaypoint(west, in: &plan, catalog: resources)
    #expect(throws: ColonyError.water) { try world.transport(plan, catalog: resources) }
    try world.plotWaypoint(northwest, in: &plan, catalog: resources)
    try world.plotWaypoint(destination, in: &plan, catalog: resources)
    #expect(world == before)
    #expect(plan.updates == max(1, Int((38_500.0 / 288 * (0.5 + 1 + 35.0 / 72)) / vehicle.airSpeed)))
    try world.transport(plan, catalog: resources)
    #expect(world.pending.first?.route.map(\.block) == [west, northwest, destination])
    #expect(world.pending.first?.estimated.totalSeconds == world.time.totalSeconds + plan.updates * 8 * 3_600)
    var random = SeededRandom()
    for _ in 1..<plan.updates {
        world.advanceToNextUpdate(catalog: resources, using: &random)
        #expect(world.land[destination]?.stock.isEmpty == true)
    }
    world.advanceToNextUpdate(catalog: resources, using: &random)
    #expect(world.land[destination]?.stock == [stock])
    #expect(world.pending.isEmpty)
    #expect(world.log.last?.description == "TRANSPORTATION")
}

@Test func landTransportRejectsWaterAndChecksSuppliesBeforeAddingAnotherLeg() throws {
    var world = try voltar()
    let resources = try catalog()
    let vehicle = try #require(resources.resources.first {
        $0.transports && $0.movable && $0.landSpeed > 0 && $0.landSpeed < 38_500.0 / 576
            && $0.basic.isEmpty && $0.active.count == 1
            && resources[$0.active[0].number]?.expendable == true
            && ($0.active[0].quantity * (resources[$0.active[0].number]?.weight ?? .infinity)) <= $0.cargoCapacity
    })
    let need = vehicle.active[0]
    let fuel = Stock(number: need.number, quantity: need.quantity, flags: 3, contents: [])
    let stock = Stock(number: vehicle.id, quantity: 1, flags: 3, contents: [])
    let origin = Block(x: 1, y: 72)
    let first = origin.moved(dx: 0, dy: 1)
    let second = first.moved(dx: 0, dy: 1)
    world.land[origin] = Land(climate: 0, altitude: 1, stock: [stock])
    world.land[first] = nil
    world.land[second] = Land(climate: 0, altitude: 1, stock: [])
    #expect(throws: ColonyError.insufficientSupplies) {
        try world.planTransport(from: origin, vehicleIndex: 0, mode: .land, catalog: resources)
    }
    world.land[origin]?.stock[0].contents = [fuel]
    var plan = try world.planTransport(from: origin, vehicleIndex: 0, mode: .land, catalog: resources)
    #expect(throws: ColonyError.invalidWaypoint) {
        try world.plotWaypoint(first, in: &plan, catalog: resources)
    }
    world.land[first] = Land(climate: 0, altitude: 1, stock: [])
    try world.plotWaypoint(first, in: &plan, catalog: resources)
    #expect(throws: ColonyError.insufficientSupplies) {
        try world.plotWaypoint(second, in: &plan, catalog: resources)
    }
    try world.plotWaypoint(origin, in: &plan, catalog: resources)
    #expect(plan.route.isEmpty)
}

@Test func dosSavesPutTheDeliveryBlockFirstOnTheFinalUpdate() throws {
    var world = try voltar()
    let resources = try catalog()
    let origin = try #require(world.base)
    let intermediate = origin.moved(dx: 1, dy: 0)
    let destination = origin.moved(dx: 2, dy: 0)
    let cargo = Stock(number: 20, quantity: 1, flags: 3, contents: [])
    world.land[destination] = Land(climate: 0, altitude: 1, stock: [])
    world.pending = [Pending(block: origin, code: Action.transportation.rawValue, started: world.time,
                             estimated: world.time, updatesLeft: 1, speed: 30, distance: 0,
                             equipment: [cargo], objects: [], route: [
                                Waypoint(block: intermediate, distance: 15),
                                Waypoint(block: destination, distance: 15)
                             ])]
    let exported = try LegacyWorld.decode(LegacyWorld.encode(world))
    #expect(exported.pending.first?.route == [Waypoint(block: destination, distance: 30)])
    var random = SeededRandom()
    world.advanceToNextUpdate(catalog: resources, using: &random)
    #expect(world.land[destination]?.stock == [cargo])
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

@Test func foodAndSeedCanUseTheSmallCombineAlternative() throws {
    let resources = try catalog()
    let combine = try #require(resources.resources.first { $0.name == "SMALL COMBINE" })
    for name in ["FOOD", "SEED"] {
        var world = try voltar()
        let block = try #require(world.base)
        let product = try #require(resources.resources.first { $0.name == name })
        let primary = try #require(product.recipe.last)
        let alternative = try #require(sequence(first: primary) { $0.alternatives.first }.first { $0.number == combine.id })
        world.land[block]?.stock = preparedProductionStock(Array(product.recipe.dropLast()) + [alternative],
                                                          quantity: 2, catalog: resources)
        world.pending = []
        try world.produce(product.id, at: block, quantity: 2, catalog: resources)
        let pending = try #require(world.pending.first)
        #expect(pending.equipment.last?.number == combine.id)
        #expect(pending.updatesLeft == Int(product.productionTime * alternative.timeFactor))
    }
}

private func preparedProductionStock(_ recipe: [Resource.Ingredient], quantity: Double,
                                     catalog: ResourceCatalog) -> [Stock] {
    func provision(_ number: Int, quantity: Double, active: Bool, depth: Int) -> Stock {
        let resource = catalog[number]
        let needs = (resource?.basic ?? []) + (active ? resource?.active ?? [] : [])
        let contents = depth > 0 ? needs.map {
            provision($0.number, quantity: $0.quantity * quantity * 10_000 + 1,
                      active: false, depth: depth - 1)
        } : []
        return Stock(number: number, quantity: quantity, flags: 3, contents: contents)
    }
    return recipe.map { provision($0.number, quantity: $0.quantity * quantity, active: true, depth: 4) }
}

private struct SeededRandom: RandomNumberGenerator {
    var state: UInt64 = 11

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
