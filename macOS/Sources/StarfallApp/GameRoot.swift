import Combine
import StarfallCore
import SwiftUI

extension Color {
    static let cockpit = Color(red: 0.055, green: 0.078, blue: 0.088)
    static let console = Color(red: 0.08, green: 0.111, blue: 0.122)
    static let terminal = Color(red: 0.55, green: 0.85, blue: 0.66)
    static let signal = Color(red: 1, green: 0.69, blue: 0.43)
}

struct GameRoot: View {
    @Bindable var game: GameSession
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let world = game.world {
                WorldConsole(game: game, world: world)
            } else {
                MainMenu(game: game)
            }
        }
        .background(Color.cockpit)
        .tint(.terminal)
        .onReceive(clock) { _ in game.tick() }
        .sheet(item: $game.sheet) { panel in
            ArchivePanel(game: game, panel: panel)
        }
        .alert("Starfall", isPresented: Binding(
            get: { game.error != nil && game.sheet == nil },
            set: { if !$0 { game.error = nil } }
        )) {
            Button("OK") { game.error = nil }
        } message: {
            Text(game.error ?? "")
        }
        .confirmationDialog("Discard unsaved colony progress?", isPresented: $game.confirmMainMenu, titleVisibility: .visible) {
            Button("Return to Main Menu", role: .destructive, action: game.discardWorld)
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct MainMenu: View {
    let game: GameSession

    var body: some View {
        HStack(spacing: 42) {
            VStack(alignment: .leading, spacing: 12) {
                if let title = game.archive?.title {
                    Image(decorative: title, scale: 1)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(1.6, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 12))
                        .accessibilityLabel("Original Starfall title screen art")
                }
                HStack {
                    ConsoleLabel("Original artwork")
                    Spacer()
                    ConsoleLabel("IBM PC · 1986")
                }
            }
            .frame(maxWidth: 540)

            VStack(alignment: .leading, spacing: 14) {
                ConsoleLabel("Interstellar colony simulation")
                Text("Starfall")
                    .font(.system(size: 53, weight: .bold, design: .monospaced))
                    .accessibilityAddTraits(.isHeader)
                Text("Command a colony on a distant world. Start with the original Voltar scenario or load another Starfall world.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Divider().padding(.vertical, 4)
                Button("Load Voltar", systemImage: "globe.americas.fill", action: game.loadVoltar)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(game.archive == nil)
                Button("Open World…", systemImage: "folder", action: game.open)
                    .disabled(game.archive == nil)
                Button("Instructions", systemImage: "book") { game.sheet = .instructions }
                    .disabled(game.archive == nil)
                Button("Hall of Fame", systemImage: "trophy") { game.sheet = .scores }
                    .disabled(game.archive == nil)
                Spacer().frame(height: 8)
                Text("Mark Porter · Originally written in Turbo Pascal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 265, alignment: .leading)
        }
        .padding(38)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WorldConsole: View {
    let game: GameSession
    let world: World
    @FocusState private var keyFocus: Bool

    var body: some View {
        let plan = game.transportPlan
        let cursor = plan?.endpoint ?? world.cursor
        let waypoints = Set(plan?.route.map(\.block) ?? [])
        VStack(alignment: .leading, spacing: 18) {
            header
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ConsoleLabel(game.zoomed ? "Sector grid · 9 × 9" : "Planetary survey · 288 × 144")
                        Spacer()
                        Button(game.zoomed ? "World Map" : "Zoom Sector",
                               systemImage: game.zoomed ? "globe.americas" : "plus.magnifyingglass",
                               action: game.toggleZoom)
                    }
                    if game.zoomed {
                        SectorGrid(world: world, cursor: cursor, waypoints: waypoints, select: game.select)
                    } else if let map = game.map {
                        WorldMap(world: world, cursor: cursor, waypoints: waypoints, terrain: map, select: game.select)
                    }
                    HStack(spacing: 15) {
                        legend("Base", color: .signal)
                        legend("Occupied", color: .terminal)
                        legend("Transport", color: .cyan)
                        if plan != nil { legend("Waypoint", color: .white) }
                        Spacer()
                        Text(plan == nil ? "Arrows to move · Space to zoom" : "Arrows to plot · Space to zoom")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .consoleCard()
                Group {
                    if let plan { routeControls(plan) } else { sidebar }
                }
                .frame(width: 244)
            }
            Spacer(minLength: 0)
            HStack {
                Button("Main Menu", systemImage: "chevron.left", action: game.leave)
                Spacer()
                Button("Open World…", systemImage: "folder", action: game.open)
                Button("Save World…", systemImage: "square.and.arrow.down", action: game.save)
            }
        }
        .padding(24)
        .focusable()
        .focusEffectDisabled()
        .focused($keyFocus)
        .onAppear { keyFocus = true }
        .onChange(of: game.sheet) { _, value in if value == nil { keyFocus = true } }
        .onKeyPress(.leftArrow, phases: [.down, .repeat]) { move(-1, 0, $0) }
        .onKeyPress(.rightArrow, phases: [.down, .repeat]) { move(1, 0, $0) }
        .onKeyPress(.upArrow, phases: [.down, .repeat]) { move(0, -1, $0) }
        .onKeyPress(.downArrow, phases: [.down, .repeat]) { move(0, 1, $0) }
        .onKeyPress(.space) { game.toggleZoom(); return .handled }
        .onKeyPress(KeyEquivalent("\u{F704}")) {
            guard game.transportPlan != nil else { return .ignored }
            game.toggleZoom()
            return .handled
        }
        .onKeyPress(.return) {
            if game.transportPlan != nil {
                if game.zoomed { game.toggleZoom() }
                return .handled
            }
            guard game.zoomed else { return .ignored }
            game.sheet = .block
            return .handled
        }
    }

    private func routeControls(_ plan: TransportPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ConsoleLabel("\(plan.mode.rawValue) transport")
            Text("Plot Waypoints").font(.title3.bold())
            Text("Start: \(plan.origin.description)\nEndpoint: \(plan.endpoint.description)")
                .font(.callout.monospaced())
            Text("\(plan.route.count) blocks · \(plan.distance.formatted(.number.precision(.fractionLength(0)))) km")
                .font(.callout.monospaced())
            if !plan.route.isEmpty {
                Text("Travel time: \(Double(plan.updates) / 3, format: .number.precision(.fractionLength(2))) days")
                    .font(.callout.monospaced())
            }
            Text("Use the arrows or click an adjacent block. Retrace the last step to undo it. Dispatch from land.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let message = game.routeMessage {
                Text(message).font(.caption).foregroundStyle(Color.signal)
            }
            HStack {
                Button("Undo Step", action: game.undoWaypoint)
                    .disabled(plan.route.isEmpty)
                Button("Cancel", action: game.cancelTransport)
                    .keyboardShortcut(.cancelAction)
            }
            Button("Dispatch", action: game.dispatchTransport)
                .keyboardShortcut(KeyEquivalent("\u{F70B}"), modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(plan.route.isEmpty || world.land[plan.endpoint] == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14).consoleCard()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                ConsoleLabel("Colony command")
                Text(world.name)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                ConsoleLabel(game.running ? "Simulation running" : "Simulation paused")
                Text(world.time.description).font(.system(.title3, design: .monospaced))
                    .monospacedDigit()
            }
            Button(game.running ? "Pause" : "Run", systemImage: game.running ? "pause.fill" : "play.fill") {
                game.running.toggle()
            }
            .buttonStyle(.borderedProminent)
            .disabled(game.transportPlan != nil)
            Menu {
                Button("Next Update", action: game.advanceUpdate)
                Button("Next Scheduled Action", action: game.advanceToNextScheduledAction)
                    .disabled(world.pending.allSatisfy { $0.action == nil })
                Divider()
                ForEach([6, 60, 240, 480], id: \.self) { minutes in
                    Button {
                        game.setClockRate(minutes: minutes)
                    } label: {
                        let label = minutes >= 60 ? "\(minutes / 60) game hours / second" : "\(minutes) game minutes / second"
                        if world.timeIncrement.totalSeconds == minutes * 60 {
                            Label(label, systemImage: "checkmark")
                        } else {
                            Text(label)
                        }
                    }
                }
            } label: {
                Label("Clock", systemImage: "clock.arrow.circlepath")
            }
            .fixedSize()
            .disabled(game.transportPlan != nil)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 9) {
                ConsoleLabel("Selected block")
                Text(world.cursor.description).font(.system(.title2, design: .monospaced))
                Text("\(world.cursor.latitude)  ·  \(world.cursor.longitude)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                if let tile = world.land[world.cursor] {
                    Text("Land · \(tile.altitudeMeters.formatted()) m")
                    Text("Temperature \(tile.temperature) · Moisture \(tile.moisture)")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Ocean").foregroundStyle(.secondary)
                }
                HStack {
                    Button("Inspect") { game.sheet = .block }
                    Button(world.cursor == world.base ? "Base Here" : "Set Base", action: game.setBase)
                        .disabled(world.land[world.cursor] == nil || world.cursor == world.base)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14).consoleCard()

            VStack(alignment: .leading, spacing: 8) {
                ConsoleLabel("Earth account")
                Text(world.balance.formatted(.number.precision(.fractionLength(0...2))) + " cr")
                    .monospacedDigit()
                    .foregroundStyle(Color.signal)
                Text(world.traderInOrbit ? "Trader in orbit" : world.traderCalled ? "Trader en route" : "No trader in orbit")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Trade", systemImage: "arrow.left.arrow.right") { game.sheet = .trade }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14).consoleCard()

            VStack(alignment: .leading, spacing: 8) {
                ConsoleLabel("Operations")
                operation("World Inventory", icon: "shippingbox", panel: .inventory)
                operation("Pending Actions (\(world.pending.count))", icon: "clock", panel: .pending)
                operation("World Log", icon: "list.bullet.rectangle", panel: .log)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14).consoleCard()
        }
    }

    private func operation(_ title: String, icon: String, panel: GameSession.Sheet) -> some View {
        Button(title, systemImage: icon) { game.sheet = panel }
    }

    private func legend(_ text: String, color: Color) -> some View {
        Label {
            Text(text)
        } icon: {
            Circle().fill(color).frame(width: 6, height: 6)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func move(_ dx: Int, _ dy: Int, _ press: KeyPress) -> KeyPress.Result {
        game.move(dx: dx, dy: dy, fast: press.modifiers.contains(.shift))
        return .handled
    }
}

struct ConsoleLabel: View {
    private let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .monospaced, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(Color.terminal)
    }
}

extension View {
    func consoleCard() -> some View {
        background(Color.console, in: .rect(cornerRadius: 13))
            .overlay { RoundedRectangle(cornerRadius: 13).strokeBorder(.white.opacity(0.09)).allowsHitTesting(false) }
    }
}
