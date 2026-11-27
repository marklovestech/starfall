import Foundation

public enum ColonyError: LocalizedError {
    case water, baseRequired, traderInOrbit, noTrader, traderAlreadyCalled
    case invalidTrade, insufficientStock, debtLimit, invalidEquipment, insufficientSupplies, invalidOperation, noRoute

    public var errorDescription: String? {
        switch self {
        case .water: "Select a land block first."
        case .baseRequired: "Establish a base before calling or trading with a ship."
        case .traderInOrbit: "The merchant will only trade at the current base."
        case .noTrader: "There is no trader in orbit."
        case .traderAlreadyCalled: "A trader is already on its way."
        case .invalidTrade: "Select a listed resource and enter a positive quantity."
        case .insufficientStock: "There is not enough unlinked stock for that transaction."
        case .debtLimit: "The purchase would exceed the colony’s debt limit."
        case .invalidEquipment: "Select compatible equipment in the block inventory."
        case .insufficientSupplies: "The selected equipment does not have enough linked basic and active supplies."
        case .invalidOperation: "Select a valid resource and quantity for this operation."
        case .noRoute: "No route reaches that land block using the selected transport mode."
        }
    }
}

public extension World {
    static let traderCallCost = 50_000.0

    mutating func setBase(at block: Block, catalog: ResourceCatalog, using random: inout some RandomNumberGenerator) throws {
        guard land[block] != nil else { throw ColonyError.water }
        guard !traderInOrbit || newPlanet else { throw ColonyError.traderInOrbit }
        let firstBase = base == nil
        base = block
        if firstBase { traderArrives(at: block, catalog: catalog, using: &random) }
    }

    mutating func callTrader(using random: inout some RandomNumberGenerator) throws {
        guard let base else { throw ColonyError.baseRequired }
        guard !traderInOrbit else { throw ColonyError.traderInOrbit }
        guard !traderCalled else { throw ColonyError.traderAlreadyCalled }
        let updates = (0..<20).reduce(0) { sum, _ in sum + Int.random(in: 6...35, using: &random) }
        pending.append(makePending(.traderArrival, at: base, updates: updates))
        traderCalled = true
        balance -= Self.traderCallCost
    }

    mutating func trade(resource number: Int, quantity: Double, buying: Bool, catalog: ResourceCatalog) throws {
        guard let base, var block = land[base] else { throw ColonyError.baseRequired }
        guard traderInOrbit else { throw ColonyError.noTrader }
        guard quantity.isFinite, quantity > 0, let resource = catalog[number],
              let index = traderStock.firstIndex(where: { $0.number == number }) else { throw ColonyError.invalidTrade }
        let amount = quantity * (buying ? resource.purchasePrice : resource.salePrice)
        guard amount.isFinite else { throw ColonyError.invalidTrade }
        if buying {
            guard balance - amount >= debtLimit else { throw ColonyError.debtLimit }
            guard traderStock[index].quantity >= quantity else { throw ColonyError.insufficientStock }
            traderStock[index].quantity -= quantity
            block.stock.insert(Stock(number: number, quantity: quantity, flags: 3, contents: []), at: 0)
            balance -= amount
        } else {
            let available = block.stock.lazy.filter { $0.number == number && $0.extracted && $0.contents.isEmpty }
                .reduce(0.0) { $0 + $1.quantity }
            guard available >= quantity else { throw ColonyError.insufficientStock }
            block.stock.consume(number, quantity: quantity, unlinkedOnly: true)
            traderStock[index].quantity += quantity
            balance += amount
        }
        land[base] = block
        updateOccupation(at: base, catalog: catalog)
    }

    func canExplore(with item: Stock, catalog: ResourceCatalog) -> Bool {
        item.extracted && item.quantity > 0 && catalog[item.number]?.explores == true
    }

    mutating func explore(at block: Block, equipmentIndex: Int, catalog: ResourceCatalog) throws {
        guard var tile = land[block] else { throw ColonyError.water }
        guard tile.stock.indices.contains(equipmentIndex),
              canExplore(with: tile.stock[equipmentIndex], catalog: catalog),
              let equipment = catalog[tile.stock[equipmentIndex].number] else { throw ColonyError.invalidEquipment }
        let stack = tile.stock[equipmentIndex]
        let duration = equipment.explorationSpeed > 0 ? 1 / (stack.quantity * equipment.explorationSpeed * 15) : 0
        let updates = Self.updateCount(duration)
        try catalog.checkSupplies([stack], steps: updates)
        tile.stock.remove(at: equipmentIndex)
        land[block] = tile
        var item = makePending(.exploration, at: block, updates: updates)
        item.equipment = [stack]
        pending.append(item)
        updateOccupation(at: block, catalog: catalog)
    }

    mutating func linkSupply(at block: Block, equipmentIndex: Int, supplyIndex: Int, quantity: Double,
                             catalog: ResourceCatalog) throws {
        guard var tile = land[block] else { throw ColonyError.water }
        guard equipmentIndex != supplyIndex, tile.stock.indices.contains(equipmentIndex),
              tile.stock.indices.contains(supplyIndex), tile.stock[equipmentIndex].extracted else {
            throw ColonyError.invalidEquipment
        }
        guard tile.stock[supplyIndex].extracted, tile.stock[supplyIndex].contents.isEmpty,
              quantity.isFinite, quantity > 0, quantity <= tile.stock[supplyIndex].quantity else {
            throw ColonyError.invalidOperation
        }
        let supply = Stock(number: tile.stock[supplyIndex].number, quantity: quantity, flags: 3, contents: [])
        tile.stock[equipmentIndex].contents.append(supply)
        tile.stock[supplyIndex].quantity -= quantity
        if tile.stock[supplyIndex].quantity == 0 { tile.stock.remove(at: supplyIndex) }
        land[block] = tile
        updateOccupation(at: block, catalog: catalog)
    }

    mutating func unlinkSupply(at block: Block, equipmentIndex: Int, supplyIndex: Int,
                               catalog: ResourceCatalog) throws {
        guard var tile = land[block] else { throw ColonyError.water }
        guard tile.stock.indices.contains(equipmentIndex),
              tile.stock[equipmentIndex].contents.indices.contains(supplyIndex) else {
            throw ColonyError.invalidOperation
        }
        let supply = tile.stock[equipmentIndex].contents.remove(at: supplyIndex)
        tile.stock.append(supply)
        land[block] = tile
        updateOccupation(at: block, catalog: catalog)
    }

    mutating func process(_ action: Action, at block: Block, objectIndex: Int, equipmentIndex: Int,
                          quantity: Double, catalog: ResourceCatalog) throws {
        guard var tile = land[block] else { throw ColonyError.water }
        guard objectIndex != equipmentIndex, tile.stock.indices.contains(objectIndex),
              tile.stock.indices.contains(equipmentIndex) else { throw ColonyError.invalidOperation }
        var input = tile.stock[objectIndex]
        let equipment = tile.stock[equipmentIndex]
        guard quantity.isFinite, quantity > 0, quantity <= input.quantity,
              let duration = catalog.processingDuration(action, input: input, equipment: equipment, quantity: quantity) else {
            throw ColonyError.invalidOperation
        }
        let updates = Self.updateCount(duration)
        try catalog.checkSupplies([equipment], steps: updates)
        tile.stock[objectIndex].quantity -= quantity
        for index in [objectIndex, equipmentIndex].sorted(by: >) {
            if index == equipmentIndex || tile.stock[index].quantity == 0 { tile.stock.remove(at: index) }
        }
        input.quantity = quantity
        var item = makePending(action, at: block, updates: updates)
        item.equipment = [equipment]
        item.objects = [input]
        pending.append(item)
        land[block] = tile
        updateOccupation(at: block, catalog: catalog)
    }

    mutating func produce(_ number: Int, at block: Block, quantity: Double, catalog: ResourceCatalog) throws {
        guard var tile = land[block] else { throw ColonyError.water }
        guard quantity.isFinite, quantity > 0, quantity.rounded(.towardZero) == quantity,
              let product = catalog[number], product.producible, !product.recipe.isEmpty else {
            throw ColonyError.invalidOperation
        }
        var ingredients = [Stock]()
        var duration = product.productionTime
        for requirement in product.recipe {
            guard let choice = ([requirement] + requirement.alternatives).first(where: {
                $0.quantity >= 0 && $0.quantity * quantity <= tile.stock.quantity(of: $0.number)
            }) else { throw ColonyError.insufficientStock }
            let amount = choice.quantity * quantity
            ingredients.append(contentsOf: tile.stock.reserve(choice.number, quantity: amount))
            duration *= choice.timeFactor
        }
        let updates = Self.updateCount(duration)
        try catalog.checkSupplies(ingredients, steps: updates)
        var item = makePending(.production, at: block, updates: updates)
        item.equipment = ingredients
        item.objects = [Stock(number: number, quantity: quantity, flags: 3, contents: [])]
        pending.append(item)
        land[block] = tile
        updateOccupation(at: block, catalog: catalog)
    }

    mutating func transport(from origin: Block, to destination: Block, vehicleIndex: Int,
                            mode: TransportMode, catalog: ResourceCatalog) throws {
        guard var tile = land[origin], land[destination] != nil else { throw ColonyError.water }
        guard tile.stock.indices.contains(vehicleIndex),
              let speed = catalog.transportSpeed(mode, vehicle: tile.stock[vehicleIndex]) else {
            throw ColonyError.invalidEquipment
        }
        guard let route = transportRoute(from: origin, to: destination, mode: mode) else { throw ColonyError.noRoute }
        let updates = Self.updateCount(ceil(route.reduce(0.0) { $0 + $1.distance } / speed))
        let vehicle = tile.stock[vehicleIndex]
        try catalog.checkSupplies([vehicle], steps: updates)
        tile.stock.remove(at: vehicleIndex)
        land[origin] = tile
        pending.append(Pending(block: origin, code: Action.transportation.rawValue, started: time,
                               estimated: GameTime(seconds: time.totalSeconds + updates * 8 * 3_600),
                               updatesLeft: updates, speed: speed, distance: 0, equipment: [vehicle], objects: [],
                               route: route))
        updateOccupation(at: origin, catalog: catalog)
    }

    private func transportRoute(from origin: Block, to destination: Block, mode: TransportMode) -> [Waypoint]? {
        guard origin != destination else { return nil }
        var previous = [origin: origin]
        var queue = [origin]
        var head = 0
        while head < queue.count && previous[destination] == nil {
            let block = queue[head]
            head += 1
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let next = block.moved(dx: dx, dy: dy)
                guard previous[next] == nil else { continue }
                switch mode {
                case .land where land[next] == nil: continue
                case .water where next == destination && land[block] != nil: continue
                case .water where next != destination && land[next] != nil: continue
                default: break
                }
                previous[next] = block
                queue.append(next)
            }
        }
        guard previous[destination] != nil else { return nil }
        var route = [Waypoint]()
        var block = destination
        while block != origin, let prior = previous[block] {
            let distance = 38_500.0 / 288 * (block.y == prior.y ? Double(prior.y) / 72 : 1)
            route.append(Waypoint(block: block, distance: distance))
            block = prior
        }
        return route.reversed()
    }

    mutating func advanceTick(catalog: ResourceCatalog, using random: inout some RandomNumberGenerator) {
        let seconds = timeIncrement.totalSeconds
        guard seconds > 0 else { return }
        time = GameTime(seconds: time.totalSeconds + seconds)
        let remaining = timeUntilUpdate.totalSeconds - seconds
        if remaining <= 0 {
            advancePending(catalog: catalog, using: &random)
            timeUntilUpdate = updateIncrement
        } else {
            timeUntilUpdate = GameTime(seconds: remaining)
        }
    }

    mutating func advanceToNextUpdate(catalog: ResourceCatalog, using random: inout some RandomNumberGenerator) {
        time = GameTime(seconds: time.totalSeconds + max(1, timeUntilUpdate.totalSeconds))
        timeUntilUpdate = updateIncrement
        advancePending(catalog: catalog, using: &random)
    }

    private mutating func advancePending(catalog: ResourceCatalog, using random: inout some RandomNumberGenerator) {
        let queue = pending
        pending = []
        var updatedLocations = Set<Block>()
        for var item in queue {
            guard let action = item.action else {
                pending.append(item)
                continue
            }
            item.updatesLeft -= 1
            if action == .transportation && item.advanceRoute() {
                complete(item, fraction: 1, catalog: catalog, using: &random)
                updatedLocations.insert(item.block)
                if let stop = item.route.first?.block { updatedLocations.insert(stop) }
            } else if item.updatesLeft <= 0 {
                complete(item, fraction: 1, catalog: catalog, using: &random)
                updatedLocations.insert(item.block)
                if let stop = item.route.first?.block { updatedLocations.insert(stop) }
            } else if !catalog.upkeep(&item.equipment, active: true) || !catalog.upkeep(&item.equipment, active: false) {
                let total = max(1, Double(item.estimated.totalSeconds - item.started.totalSeconds) / (8 * 3_600))
                let fraction = min(1, max(0, 1 - Double(item.updatesLeft) / total))
                complete(item, fraction: fraction, catalog: catalog, using: &random)
                updatedLocations.insert(item.block)
                if let stop = item.route.first?.block { updatedLocations.insert(stop) }
            } else {
                pending.append(item)
            }
        }
        for block in updatedLocations { updateOccupation(at: block, catalog: catalog) }
        for block in occupied {
            guard var tile = land[block] else { continue }
            _ = catalog.upkeep(&tile.stock, active: false)
            land[block] = tile
        }
    }

    private mutating func complete(_ item: Pending, fraction: Double, catalog: ResourceCatalog,
                                   using random: inout some RandomNumberGenerator) {
        guard let action = item.action else { return }
        if action == .traderArrival {
            traderArrives(at: base ?? item.block, catalog: catalog, using: &random)
            return
        }
        if action == .traderDeparture {
            traderInOrbit = false
            newPlanet = false
            traderStock = []
            log.append(LogEntry(block: base ?? item.block, description: "TRADER LEFT", completed: time))
            return
        }

        let destination = action == .transportation ? item.route.first?.block ?? item.block : item.block
        let block = land[destination] != nil ? destination : item.block
        guard var tile = land[block] else { return }
        var equipment = item.equipment
        var output: [Stock] = []
        switch action {
        case .exploration:
            for tool in equipment {
                guard let detector = catalog[tool.number] else { continue }
                for index in tile.stock.indices where !tile.stock[index].found && !tile.stock[index].extracted {
                    guard let deposit = catalog[tile.stock[index].number] else { continue }
                    for (effectiveness, sensitivity) in zip(detector.tests, deposit.tests) {
                        let chance = Int(fraction * Double(effectiveness * sensitivity) / 100)
                        if Int.random(in: 0..<100, using: &random) <= chance { tile.stock[index].flags |= 1 }
                    }
                }
            }
        case .extraction, .development, .refinement:
            for var input in item.objects {
                guard let resource = catalog[input.number] else { continue }
                let result = action == .development ? resource.developmentResult
                    : action == .refinement ? resource.refinementResult : input.number
                guard result != 0 else { output.append(input); continue }
                let yield = action == .extraction ? 1.0 : resource.purity
                let finished = input.quantity * fraction * yield
                if fraction == 1 {
                    output.append(Stock(number: result, quantity: finished, flags: input.flags | 3, contents: input.contents))
                } else {
                    if finished > 0 {
                        output.append(Stock(number: result, quantity: finished, flags: 3, contents: []))
                    }
                    input.quantity *= 1 - fraction
                    output.append(input)
                }
            }
        case .production:
            if var product = item.objects.first {
                product.quantity = (product.quantity * fraction).rounded(.towardZero)
                let used = product.quantity / max(1, item.objects[0].quantity)
                if used == 1 {
                    equipment = equipment.flatMap(\.contents)
                } else {
                    for index in equipment.indices { equipment[index].quantity *= 1 - used }
                }
                if product.quantity > 0 { output.append(product) }
            }
        case .transportation, .traderArrival, .traderDeparture:
            break
        }
        tile.stock.insert(contentsOf: equipment.reversed(), at: 0)
        tile.stock.insert(contentsOf: output.reversed(), at: 0)
        land[block] = tile
        log.append(LogEntry(block: item.block, description: action.logDescription, completed: time))
    }

    private func makePending(_ action: Action, at block: Block, updates: Int) -> Pending {
        Pending(block: block, code: action.rawValue, started: time,
                estimated: GameTime(seconds: time.totalSeconds + updates * 8 * 3_600), updatesLeft: updates,
                speed: 0, distance: 0, equipment: [], objects: [], route: [])
    }

    private static func updateCount(_ duration: Double) -> Int {
        if duration.isNaN { return 0 }
        return Int(min(32_767, max(0, duration)))
    }

    private mutating func traderArrives(at block: Block, catalog: ResourceCatalog, using random: inout some RandomNumberGenerator) {
        traderCalled = false
        traderInOrbit = true
        debtLimit -= Self.traderCallCost
        let stay = (0..<10).reduce(0) { sum, _ in sum + Int.random(in: 3...17, using: &random) } / 15
        pending.append(makePending(.traderDeparture, at: block, updates: stay))
        log.append(LogEntry(block: block, description: "TRADER ARRIVED", completed: time))
        traderStock = catalog.resources.reversed().compactMap { resource in
            guard resource.typicalTraderAmount != 0 else { return nil }
            var amount = 0
            if resource.typicalTraderAmount > 0 {
                var step = resource.typicalTraderAmount
                var steps = 2
                repeat {
                    step /= 2
                    steps += 1
                } while step >= 32_767
                for _ in 0..<(steps * 2) { amount += Int.random(in: 0...Int(step), using: &random) }
                if amount == 0 && Int.random(in: 0..<3, using: &random) != 0 { amount = 1 }
            }
            return Stock(number: resource.id, quantity: Double(amount), flags: 3, contents: [])
        }
        updateOccupation(at: block, catalog: catalog)
    }

    private mutating func updateOccupation(at block: Block, catalog: ResourceCatalog) {
        if (land[block]?.stock.contains(where: { catalog.isOccupied(by: $0) }) ?? false)
            || pending.contains(where: { $0.block == block && $0.action != .transportation }) {
            occupied.insert(block)
        } else {
            occupied.remove(block)
        }
    }
}

private extension Action {
    var logDescription: String {
        switch self {
        case .extraction: "MINERAL EXTRACTION"
        case .development: "SURFACE DEVELOPMENT"
        case .refinement: "MINERAL REFINEMENT"
        case .production: "RESOURCE PRODUCTION"
        default: title.uppercased()
        }
    }
}

private extension Pending {
    mutating func advanceRoute() -> Bool {
        distance += speed
        while let next = route.first, distance >= next.distance {
            if route.count == 1 { return true }
            distance -= next.distance
            route.removeFirst()
        }
        return false
    }
}

public extension ResourceCatalog {
    func transportSpeed(_ mode: TransportMode, vehicle: Stock) -> Double? {
        guard let resource = self[vehicle.number], vehicle.extracted, vehicle.quantity > 0,
              resource.transports, isMovable(vehicle), cargoWeight(vehicle.contents) <= resource.cargoCapacity * vehicle.quantity else {
            return nil
        }
        let speed = switch mode {
        case .air: resource.airSpeed
        case .land: resource.landSpeed
        case .water: resource.waterSpeed
        }
        return speed > 0 ? speed : nil
    }

    func processingDuration(_ action: Action, input: Stock, equipment: Stock, quantity: Double) -> Double? {
        guard input.found, input.contents.isEmpty, equipment.extracted, equipment.quantity > 0,
              let material = self[input.number], let tool = self[equipment.number] else { return nil }
        let work: Double
        let rate: Double
        switch action {
        case .extraction where !input.extracted && material.extractable && tool.extracts:
            work = material.extractionSpeed
            rate = tool.extractionSpeed
        case .development where material.developable && tool.develops
            && material.developmentEquipment?.contains(tool.id) == true:
            work = material.developmentSpeed
            rate = tool.developmentSpeed / 100
        case .refinement where input.extracted && material.refinable && tool.refines
            && material.refinementEquipment?.contains(tool.id) == true:
            work = material.refinementSpeed
            rate = tool.refinementSpeed / 100
        default: return nil
        }
        guard work > 0, rate > 0 else { return nil }
        return quantity / work / equipment.quantity / rate / 15
    }
}

private extension ResourceCatalog {
    func isMovable(_ stock: Stock) -> Bool {
        self[stock.number]?.movable == true && stock.contents.allSatisfy(isMovable)
    }

    func cargoWeight(_ stock: [Stock]) -> Double {
        stock.reduce(0) { $0 + ($1.quantity * (self[$1.number]?.weight ?? 0)) + cargoWeight($1.contents) }
    }

    func checkSupplies(_ stock: [Stock], steps: Int) throws {
        var stock = stock
        guard upkeep(&stock, active: true, steps: steps, consume: false),
              upkeep(&stock, active: false, steps: steps, consume: false) else {
            throw ColonyError.insufficientSupplies
        }
    }

    func isOccupied(by item: Stock) -> Bool {
        guard let resource = self[item.number] else { return false }
        return !resource.naturallyOccurring || (resource.extractable && (item.found || item.extracted))
            || item.contents.contains(where: { isOccupied(by: $0) })
    }

    func upkeep(_ stock: inout [Stock], active: Bool, steps: Int = 1, consume: Bool = true) -> Bool {
        var sufficient = true
        for index in stock.indices {
            guard let resource = self[stock[index].number] else { continue }
            for need in active ? resource.active : resource.basic {
                let expendable = self[need.number]?.expendable == true
                let required = need.quantity * stock[index].quantity * Double(expendable ? steps : 1)
                let amount = stock[index].contents.lazy.filter { $0.number == need.number && $0.extracted }
                    .reduce(0.0) { $0 + $1.quantity }
                if amount < required { sufficient = false }
                if consume && expendable {
                    stock[index].contents.consume(need.number, quantity: min(amount, required))
                }
            }
            if !active && !upkeep(&stock[index].contents, active: false, steps: steps, consume: consume) {
                sufficient = false
            }
        }
        return sufficient
    }
}

private extension Array where Element == Stock {
    func quantity(of number: Int) -> Double {
        lazy.filter { $0.number == number && $0.extracted && $0.quantity > 0 }
            .reduce(0.0) { $0 + $1.quantity }
    }

    mutating func reserve(_ number: Int, quantity: Double) -> [Stock] {
        var remaining = quantity
        var taken = [Stock]()
        var index = 0
        while index < count && remaining > 0 {
            if self[index].number == number && self[index].extracted && self[index].quantity > 0 {
                if self[index].quantity <= remaining {
                    remaining -= self[index].quantity
                    taken.append(remove(at: index))
                    continue
                }
                let share = remaining / self[index].quantity
                taken.append(self[index].takeFraction(share))
                remaining = 0
            }
            index += 1
        }
        return taken
    }

    mutating func consume(_ number: Int, quantity: Double, unlinkedOnly: Bool = false) {
        var remaining = quantity
        var index = 0
        while remaining > 0 && index < count {
            if self[index].number == number && self[index].extracted && (!unlinkedOnly || self[index].contents.isEmpty) {
                let removed = Swift.min(remaining, Swift.max(0, self[index].quantity))
                remaining -= removed
                self[index].quantity -= removed
                if self[index].quantity <= 0 && self[index].contents.isEmpty {
                    remove(at: index)
                    continue
                }
            }
            index += 1
        }
    }
}

private extension Stock {
    mutating func takeFraction(_ fraction: Double) -> Stock {
        var withdrawn = self
        withdrawn.quantity *= fraction
        quantity -= withdrawn.quantity
        for index in contents.indices { withdrawn.contents[index] = contents[index].takeFraction(fraction) }
        return withdrawn
    }
}
