import StarfallCore
import SwiftUI

struct ArchivePanel: View {
    let game: GameSession
    let panel: GameSession.Sheet
    @State private var blockOnly: Bool
    @State private var inventoryByBlock = true
    @State private var actionToCancel: Int?
    @State private var stockToSplit: Int?
    @State private var splitQuantity = 1.0

    init(game: GameSession, panel: GameSession.Sheet) {
        self.game = game
        self.panel = panel
        _blockOnly = State(initialValue: game.zoomed)
    }

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
                case .scores: scores(game.scores)
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
        VStack(alignment: .leading) {
            Picker("Group by", selection: $inventoryByBlock) {
                Text("Block").tag(true)
                Text("Resource Totals").tag(false)
            }
            .pickerStyle(.segmented)
            if inventoryByBlock {
                inventoryLocations(world, catalog: catalog)
            } else {
                let amounts = world.inventory
                List(amounts.keys.sorted(), id: \.self) { number in
                    itemRow(name: catalog[number]?.name ?? "Resource \(number)", value: amounts[number, default: 0],
                            units: catalog[number]?.units ?? "")
                }
                .overlay { if amounts.isEmpty { ContentUnavailableView("No stock", systemImage: "shippingbox") } }
            }
        }
    }

    private func inventoryLocations(_ world: World, catalog: ResourceCatalog) -> some View {
        let blocks = world.occupied.filter { block in
            world.land[block]?.stock.contains { $0.found || $0.extracted } == true
        }.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        return List(blocks, id: \.self) { block in
            let items = (world.land[block]?.stock ?? []).filter { $0.found || $0.extracted }
            DisclosureGroup {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    StockRow(item: item, catalog: catalog)
                }
            } label: {
                HStack {
                    Text("Block \(block.description)")
                    if block == world.base { Text("Base").foregroundStyle(.secondary) }
                    Spacer()
                    Button("Inspect") { game.inspect(block) }.buttonStyle(.bordered)
                }
            }
        }
        .overlay { if blocks.isEmpty { ContentUnavailableView("No stock", systemImage: "shippingbox") } }
    }

    private func log(_ world: World) -> some View {
        let entries = world.log.enumerated().reversed().filter { !blockOnly || $0.element.block == world.cursor }
        return VStack(alignment: .leading) {
            reportScope(world.cursor)
            List(entries, id: \.offset) { _, entry in
                HStack {
                    Text(entry.description)
                    Spacer()
                    Text(entry.block.description).foregroundStyle(.secondary)
                    Text(entry.completed.description).foregroundStyle(.secondary).monospacedDigit()
                }
            }
            .overlay { if entries.isEmpty { ContentUnavailableView("No log entries", systemImage: "list.bullet") } }
        }
    }

    private func pending(_ world: World) -> some View {
        let actions = world.pending.enumerated().filter { !blockOnly || $0.element.block == world.cursor }
        return VStack(alignment: .leading) {
            reportScope(world.cursor)
            List(actions, id: \.offset) { index, item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).fontWeight(.medium)
                        Text("Block \(item.block.description) · \(max(0, item.updatesLeft)) updates remaining")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(item.estimated.description).monospacedDigit()
                    if item.canCancel, game.transportPlan == nil {
                        Button(item.action == .traderDeparture ? "Dismiss Trader…" : "Cancel Action…") {
                            actionToCancel = index
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
            .overlay { if actions.isEmpty { ContentUnavailableView("No pending actions", systemImage: "clock") } }
        }
        .alert("End this pending action?", isPresented: Binding(
            get: { actionToCancel != nil },
            set: { if !$0 { actionToCancel = nil } }
        )) {
            Button("Keep Action", role: .cancel) {}
            Button("End Action", role: .destructive) {
                if let actionToCancel { game.cancelPending(index: actionToCancel) }
            }
        } message: {
            Text("This cannot be undone. Any work already completed is kept.")
        }
    }

    private func reportScope(_ block: Block) -> some View {
        Picker("Show", selection: $blockOnly) {
            Text("Entire World").tag(false)
            Text("Block \(block.description)").tag(true)
        }
        .pickerStyle(.segmented)
    }

    private func resourceList(_ land: Land, world: World, catalog: ResourceCatalog) -> some View {
        List {
            ForEach(Array(land.stock.enumerated()).filter { $0.element.found || $0.element.extracted },
                    id: \.offset) { index, item in
                let canCombine = land.stock.indices.contains { $0 != index && item.canCombine(with: land.stock[$0]) }
                StockRow(item: item, catalog: catalog,
                         unlink: { game.unlinkSupply(equipmentIndex: index, supplyIndex: $0) },
                         explore: world.canExplore(with: item, catalog: catalog)
                            ? { game.explore(equipmentIndex: index) } : nil,
                         split: item.quantity > 1 ? { splitQuantity = 1; stockToSplit = index } : nil,
                         combine: canCombine ? { game.combineStock(index: index) } : nil)
            }
        }
        .alert("Split resource stack", isPresented: Binding(
            get: { stockToSplit != nil },
            set: { if !$0 { stockToSplit = nil } }
        )) {
            TextField("Quantity", value: $splitQuantity, format: .number)
            Button("Cancel", role: .cancel) {}
            Button("Split") {
                if let stockToSplit { game.splitStock(index: stockToSplit, quantity: splitQuantity) }
            }
        } message: {
            Text("Enter the amount to move into a new stack. Linked supplies stay with the original stack.")
        }
    }

    @ViewBuilder private func block(_ world: World, catalog: ResourceCatalog) -> some View {
        if let land = world.land[world.cursor] {
            Text("Discovered resources and linked equipment at this block.")
                .foregroundStyle(.secondary)
            resourceList(land, world: world, catalog: catalog)
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
            Spacer()
            Button("Plot Route") {
                if let object { game.planTransport(vehicleIndex: object, mode: mode) }
            }
            .disabled(object == nil)
        }
    }

    private var objectIndices: [Int] {
        land.stock.indices.filter { index in
            let item = land.stock[index]
            guard item.quantity > 0 else { return false }
            if order == .supply { return item.extracted }
            return item.contents.isEmpty && !tools(for: index).isEmpty
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
    var split: (() -> Void)?
    var combine: (() -> Void)?
    var unlinkFromParent: (() -> Void)?

    var body: some View {
        if item.contents.isEmpty {
            row
        } else {
            DisclosureGroup {
                ForEach(Array(item.contents.enumerated()), id: \.offset) { index, child in
                    StockRow(item: child, catalog: catalog,
                             unlinkFromParent: unlink.map { action in { action(index) } })
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
            if let split { Button("Split…", action: split).buttonStyle(.bordered) }
            if let combine { Button("Combine", action: combine).buttonStyle(.bordered) }
            if let unlinkFromParent { Button("Unlink", action: unlinkFromParent).buttonStyle(.bordered) }
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
