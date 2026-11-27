import StarfallCore
import SwiftUI

struct ArchivePanel: View {
    let game: GameSession
    let panel: GameSession.Sheet

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Done") { game.error = nil; game.sheet = nil }
                    .keyboardShortcut(.cancelAction)
            }
            Divider()
            if let archive = game.archive {
                switch panel {
                case .instructions: InstructionsPanel(topics: archive.help)
                case .scores: scores(archive.scores)
                case .inventory, .pending, .log, .trade, .block:
                    if let world = game.world {
                        switch panel {
                        case .inventory: inventory(world, catalog: archive.catalog)
                        case .pending: pending(world)
                        case .log: log(world)
                        case .trade: TradePanel(game: game, world: world, catalog: archive.catalog)
                        case .block: block(world, catalog: archive.catalog)
                        default: EmptyView()
                        }
                    }
                }
            }
            if let message = game.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(message)
                    Spacer()
                    Button("Dismiss") { game.error = nil }
                }
                .foregroundStyle(Color.signal)
            }
        }
        .padding(22)
        .frame(width: 700, height: 470)
    }

    private var title: String {
        switch panel {
        case .instructions: "Starfall Instructions"
        case .scores: "Hall of Fame"
        case .inventory: "World Inventory"
        case .pending: "Pending Actions"
        case .log: "World Log"
        case .trade: "Orbital Trade"
        case .block: "Block \(game.world?.cursor.description ?? "")"
        }
    }

    private func scores(_ scores: [HallOfFameEntry]) -> some View {
        Table(scores) {
            TableColumn("Rank") { Text("#\($0.rank)") }.width(42)
            TableColumn("Colonist", value: \.name)
            TableColumn("World", value: \.world)
            TableColumn("Score") { Text($0.score.formatted(.number.precision(.fractionLength(0)))) }
        }
    }

    private func inventory(_ world: World, catalog: ResourceCatalog) -> some View {
        let amounts = world.inventory
        return List(amounts.keys.sorted(), id: \.self) { number in
            itemRow(name: catalog[number]?.name ?? "Resource \(number)", value: amounts[number, default: 0],
                    units: catalog[number]?.units ?? "")
        }
        .overlay { if amounts.isEmpty { ContentUnavailableView("No stock", systemImage: "shippingbox") } }
    }

    private func log(_ world: World) -> some View {
        List(Array(world.log.enumerated().reversed()), id: \.offset) { _, entry in
            HStack {
                Text(entry.description)
                Spacer()
                Text(entry.block.description).foregroundStyle(.secondary)
                Text(entry.completed.description).foregroundStyle(.secondary).monospacedDigit()
            }
        }
        .overlay { if world.log.isEmpty { ContentUnavailableView("No log entries", systemImage: "list.bullet") } }
    }

    private func pending(_ world: World) -> some View {
        List(Array(world.pending.enumerated()), id: \.offset) { _, action in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(action.title).fontWeight(.medium)
                    Spacer()
                    Text(action.estimated.description).monospacedDigit()
                }
                Text("Block \(action.block.description) · \(max(0, action.updatesLeft)) updates remaining")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .overlay { if world.pending.isEmpty { ContentUnavailableView("No pending actions", systemImage: "clock") } }
    }

    @ViewBuilder private func block(_ world: World, catalog: ResourceCatalog) -> some View {
        if let land = world.land[world.cursor] {
            Text("Discovered resources and linked equipment at this block.")
                .foregroundStyle(.secondary)
            List {
                ForEach(Array(land.stock.enumerated()).filter { $0.element.found || $0.element.extracted },
                        id: \.offset) { index, item in
                    StockRow(item: item, catalog: catalog,
                             unlink: { game.unlinkSupply(equipmentIndex: index, supplyIndex: $0) },
                             explore: world.canExplore(with: item, catalog: catalog) ? { game.explore(equipmentIndex: index) } : nil)
                }
            }
            BlockOperations(game: game, world: world, land: land, catalog: catalog)
            .overlay {
                if !land.stock.contains(where: { $0.found || $0.extracted }) {
                    ContentUnavailableView("No discovered resources", systemImage: "binoculars")
                }
            }
        } else {
            ContentUnavailableView("Ocean block", systemImage: "water.waves")
        }
    }
}

private struct BlockOperations: View {
    enum Order: String, CaseIterable {
        case extraction = "Extraction", development = "Development", refinement = "Refinement"
        case production = "Production", transport = "Transport", supply = "Link Supplies"

        var action: Action? {
            switch self {
            case .extraction: .extraction
            case .development: .development
            case .refinement: .refinement
            default: nil
            }
        }
    }

    let game: GameSession
    let world: World
    let land: Land
    let catalog: ResourceCatalog
    @State private var order = Order.extraction
    @State private var object: Int?
    @State private var equipment: Int?
    @State private var quantity = 1.0
    @State private var mode = TransportMode.land
    @State private var x = 1
    @State private var y = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Picker("Operation", selection: $order) {
                ForEach(Order.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: order) { _, _ in reset() }
            if order == .transport {
                transportFields
            } else {
                HStack {
                    Picker(order == .supply ? "Supply" : "Resource", selection: $object) {
                        Text("Select").tag(Int?.none)
                        if order == .production {
                            ForEach(catalog.resources.filter(\.producible)) { Text($0.name).tag(Optional($0.id)) }
                        } else {
                            ForEach(objectIndices, id: \.self) { Text(stockLabel($0)).tag(Optional($0)) }
                        }
                    }
                    .onChange(of: object) { _, _ in equipment = nil }
                    if order != .production {
                        Picker("Equipment", selection: $equipment) {
                            Text("Select").tag(Int?.none)
                            ForEach(equipmentIndices, id: \.self) { Text(stockLabel($0)).tag(Optional($0)) }
                        }
                        .disabled(object == nil)
                    }
                }
                HStack {
                    TextField("Quantity", value: $quantity, format: .number)
                        .frame(width: 160)
                    Spacer()
                    Button(order == .supply ? "Link Supply" : "Queue Action", action: execute)
                        .disabled(object == nil || (order != .production && equipment == nil))
                }
            }
        }
        .padding(12)
        .consoleCard()
        .onChange(of: land.stock) { _, _ in reset() }
    }

    private var transportFields: some View {
        let destination = Block(x: x, y: y)
        return VStack(alignment: .leading, spacing: 9) {
            HStack {
                Picker("Mode", selection: $mode) {
                    ForEach(TransportMode.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                .onChange(of: mode) { _, _ in object = nil }
                Picker("Vehicle", selection: $object) {
                    Text("Select").tag(Int?.none)
                    ForEach(land.stock.indices.filter { catalog.transportSpeed(mode, vehicle: land.stock[$0]) != nil },
                            id: \.self) { Text(stockLabel($0)).tag(Optional($0)) }
                }
            }
            HStack {
                Text("Destination").foregroundStyle(.secondary)
                TextField("X", value: $x, format: .number).frame(width: 95)
                TextField("Y", value: $y, format: .number).frame(width: 95)
                if let base = world.base, base != world.cursor {
                    Button("Use Base") { x = base.x; y = base.y }
                }
                Spacer()
                Button("Dispatch") {
                    if let object { game.transport(vehicleIndex: object, to: destination, mode: mode) }
                }
                .disabled(object == nil || destination == world.cursor || world.land[destination] == nil)
            }
        }
    }

    private var objectIndices: [Int] {
        land.stock.indices.filter { index in
            let item = land.stock[index]
            guard item.quantity > 0, item.contents.isEmpty else { return false }
            if order == .supply { return item.extracted }
            return !tools(for: index).isEmpty
        }
    }

    private var equipmentIndices: [Int] {
        guard let object, land.stock.indices.contains(object) else { return [] }
        return tools(for: object)
    }

    private func tools(for object: Int) -> [Int] {
        land.stock.indices.filter { index in
            guard index != object else { return false }
            let tool = land.stock[index]
            if let action = order.action {
                return catalog.processingDuration(action, input: land.stock[object], equipment: tool, quantity: 1) != nil
            }
            return order == .supply && tool.extracted && tool.quantity > 0
        }
    }

    private func stockLabel(_ index: Int) -> String {
        let item = land.stock[index]
        return "\(catalog[item.number]?.name ?? String(item.number)) · \(item.quantity.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private func execute() {
        guard let object else { return }
        if order == .production {
            game.produce(object, quantity: quantity)
        } else if let equipment {
            if let action = order.action {
                game.process(action, objectIndex: object, equipmentIndex: equipment, quantity: quantity)
            } else {
                game.linkSupply(equipmentIndex: equipment, supplyIndex: object, quantity: quantity)
            }
        }
    }

    private func reset() {
        object = nil
        equipment = nil
        quantity = 1
        x = world.cursor.x
        y = world.cursor.y
    }
}

private struct InstructionsPanel: View {
    let topics: [HelpTopic]
    @State private var topicIndex = 0
    @State private var pageIndex = 0

    var body: some View {
        if topics.indices.contains(topicIndex) {
            let topic = topics[topicIndex]
            Picker("Topic", selection: $topicIndex) {
                ForEach(topics.indices, id: \.self) { Text(topics[$0].title).tag($0) }
            }
            .onChange(of: topicIndex) { _, _ in pageIndex = 0 }
            ScrollView {
                Text(topic.pages[min(pageIndex, topic.pages.count - 1)])
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .id("\(topicIndex)-\(pageIndex)")
            .consoleCard()
            HStack {
                Button("Previous Page") { pageIndex -= 1 }.disabled(pageIndex == 0)
                Spacer()
                Text("Page \(pageIndex + 1) of \(topic.pages.count)")
                Spacer()
                Button("Next Page") { pageIndex += 1 }.disabled(pageIndex >= topic.pages.count - 1)
            }
        }
    }
}

private struct StockRow: View {
    let item: Stock
    let catalog: ResourceCatalog
    var unlink: ((Int) -> Void)?
    var explore: (() -> Void)?

    var body: some View {
        if item.contents.isEmpty {
            row
        } else {
            DisclosureGroup {
                ForEach(Array(item.contents.enumerated()), id: \.offset) { index, child in
                    HStack {
                        StockRow(item: child, catalog: catalog)
                        if let unlink { Button("Unlink") { unlink(index) }.buttonStyle(.bordered) }
                    }
                }
            } label: {
                row
            }
        }
    }

    private var row: some View {
        let info = catalog[item.number]
        return HStack {
            itemRow(name: info?.name ?? "Resource \(item.number)", value: item.quantity, units: info?.units ?? "")
            if !item.extracted { Text("Unextracted").font(.caption).foregroundStyle(.secondary) }
            if let explore { Button("Explore", action: explore).buttonStyle(.bordered) }
        }
    }
}

private struct TradePanel: View {
    let game: GameSession
    let world: World
    let catalog: ResourceCatalog
    @State private var resourceNumber: Int?
    @State private var quantity = 1.0
    @State private var confirmCall = false

    var body: some View {
        if world.base == nil {
            ContentUnavailableView("No base established", systemImage: "flag",
                                   description: Text("Set a base on land before opening trade."))
        } else if !world.traderInOrbit {
            VStack(spacing: 12) {
                ContentUnavailableView(world.traderCalled ? "Trader en route" : "No trader in orbit",
                                       systemImage: "antenna.radiowaves.left.and.right")
                if world.traderCalled {
                    if let arrival = world.pending.first(where: { $0.action == .traderArrival }) {
                        Text("Estimated arrival: \(arrival.estimated.description)")
                    }
                    Text("Close this window to run the clock or advance the next update.").foregroundStyle(.secondary)
                } else {
                    Button("Call Trader · 50,000 cr") { confirmCall = true }
                        .buttonStyle(.borderedProminent)
                        .confirmationDialog("Call an orbital trader?", isPresented: $confirmCall, titleVisibility: .visible) {
                            Button("Call Trader") { game.callTrader() }
                        } message: {
                            Text("The call debits 50,000 credits from the Earth account.")
                        }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack {
                Text("Balance: \(credits(world.balance))")
                Spacer()
                Text("Debt limit: \(credits(world.debtLimit))")
            }
            .foregroundStyle(Color.signal)
            Table(world.traderStock.compactMap { item -> TradeRow? in
                guard let resource = catalog[item.number] else { return nil }
                let available = world.base.flatMap { world.land[$0] }?.stock.filter {
                    $0.number == item.number && $0.extracted && $0.contents.isEmpty
                }.reduce(0.0) { $0 + $1.quantity } ?? 0
                return TradeRow(resource: resource, traderQuantity: item.quantity, colonyQuantity: available)
            }, selection: $resourceNumber) {
                TableColumn("Resource") { Text($0.resource.name) }
                TableColumn("Trader") { Text($0.traderQuantity.formatted()) }.width(80)
                TableColumn("At Base") { Text($0.colonyQuantity.formatted()) }.width(80)
                TableColumn("Buy / unit") { Text(credits($0.resource.purchasePrice)) }.width(104)
                TableColumn("Sell / unit") { Text(credits($0.resource.salePrice)) }.width(104)
            }
            HStack {
                TextField("Quantity", value: $quantity, format: .number)
                    .frame(width: 180)
                Spacer()
                Button("Sell") { trade(buying: false) }.disabled(resourceNumber == nil)
                Button("Buy") { trade(buying: true) }.disabled(resourceNumber == nil)
            }
        }
    }

    private func trade(buying: Bool) {
        if let resourceNumber { game.trade(number: resourceNumber, quantity: quantity, buying: buying) }
    }

    private func credits(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2))) + " cr"
    }

    private struct TradeRow: Identifiable {
        let resource: Resource
        let traderQuantity: Double
        let colonyQuantity: Double
        var id: Int { resource.id }
    }
}

@MainActor
private func itemRow(name: String, value: Double, units: String) -> some View {
    HStack {
        Text(name)
        Spacer()
        Text(value.formatted(.number.precision(.fractionLength(0...2))) + " " + units)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}
