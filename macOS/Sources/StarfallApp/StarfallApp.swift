import AppKit
import Observation
import StarfallCore
import SwiftUI

@main
struct StarfallApp: App {
    @NSApplicationDelegateAdaptor(StarfallAppDelegate.self) private var delegate
    @State private var game = GameSession()

    var body: some Scene {
        Window("Starfall", id: "starfall") {
            GameRoot(game: game)
                .onAppear { delegate.game = game }
                .frame(minWidth: 880, minHeight: 620)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1_070, height: 740)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New World…", action: game.promptNewWorld)
                    .keyboardShortcut("n")
                    .disabled(game.archive == nil)
                Button("Open World…", action: game.open)
                    .keyboardShortcut("o")
                    .disabled(game.archive == nil)
                Button("Load Voltar", action: game.loadVoltar)
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    .disabled(game.archive == nil)
                Button("Save World…", action: game.save)
                    .keyboardShortcut("s")
                    .disabled(game.world == nil)
            }
            CommandMenu("Colony") {
                Button(game.running ? "Pause Clock" : "Run Clock") { game.running.toggle() }
                    .keyboardShortcut("t")
                    .disabled(game.world == nil || game.sheet != nil)
                Button("Advance One Update", action: game.advanceUpdate)
                    .keyboardShortcut(".", modifiers: [.command, .shift])
                    .disabled(game.world == nil || game.sheet != nil)
                Divider()
                Button("World Inventory") { game.sheet = .inventory }
                    .keyboardShortcut("i")
                    .disabled(game.world == nil)
                Button("Trade") { game.sheet = .trade }
                    .keyboardShortcut("2")
                    .disabled(game.world == nil)
                Button("Pending Actions") { game.sheet = .pending }
                    .keyboardShortcut("9")
                    .disabled(game.world == nil)
                Button("World Log") { game.sheet = .log }
                    .keyboardShortcut("0")
                    .disabled(game.world == nil)
            }
            CommandGroup(replacing: .help) {
                Button("Starfall Instructions") { game.sheet = .instructions }
                    .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}

@MainActor
final class StarfallAppDelegate: NSObject, NSApplicationDelegate {
    weak var game: GameSession?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        game?.confirmDiscard("Quit Starfall?", button: "Quit Without Saving") == false ? .terminateCancel : .terminateNow
    }
}

@MainActor @Observable
final class GameSession {
    enum Sheet: String, Identifiable {
        case newWorld, instructions, scores, inventory, pending, log, trade, block
        var id: Self { self }
    }

    var world: World?
    var sheet: Sheet?
    var error: String?
    var archive: Archive?
    var map: CGImage?
    var zoomed = false
    var running = false
    var modified = false
    var confirmMainMenu = false
    private var random = SystemRandomNumberGenerator()

    init() {
        do { archive = try Archive() }
        catch { self.error = error.localizedDescription }
    }

    func promptNewWorld() {
        guard archive != nil else { return }
        if world != nil {
            guard confirmDiscard("Replace the current world?", button: "Create New World") else { return }
        }
        running = false
        sheet = .newWorld
    }

    func createNewWorld(named name: String) {
        guard let archive else { return }
        do {
            let next = World.generate(named: name, catalog: archive.catalog, using: &random)
            try install(next, modified: true)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadVoltar() {
        guard let archive else { return }
        replaceWorld { try load(archive.sampleWorld) }
    }

    func open() {
        let panel = NSOpenPanel()
        panel.title = "Open Starfall World"
        panel.message = "Choose an original or native-saved Starfall world (.DAT)."
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        running = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        replaceWorld {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 16 * 1_024 * 1_024 else { throw ArchiveError.binary("file is too large") }
            try load(Data(contentsOf: url))
        }
    }

    func save() {
        guard let world else { return }
        let panel = NSSavePanel()
        panel.title = "Save Starfall World"
        let filename = world.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        panel.nameFieldStringValue = filename.isEmpty ? "WORLD.DAT" : filename + ".DAT"
        running = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try LegacyWorld.encode(world).write(to: url, options: .atomic)
            modified = false
        } catch {
            self.error = error.localizedDescription
        }
    }

    func leave() {
        if modified {
            running = false
            confirmMainMenu = true
        } else {
            discardWorld()
        }
    }

    func discardWorld() {
        world = nil
        map = nil
        running = false
        zoomed = false
        modified = false
    }

    func select(_ block: Block) {
        guard block.isOnMap else { return }
        world?.cursor = block
    }

    func move(dx: Int, dy: Int, fast: Bool) {
        guard let cursor = world?.cursor else { return }
        let step = fast ? 8 : 1
        select(cursor.moved(dx: dx * step, dy: dy * step))
    }

    func toggleZoom() { zoomed.toggle() }

    func setBase() {
        edit { world, archive in try world.setBase(at: world.cursor, catalog: archive.catalog, using: &random) }
    }

    func callTrader() {
        edit { world, _ in try world.callTrader(using: &random) }
    }

    func trade(number: Int, quantity: Double, buying: Bool) {
        edit { world, archive in
            try world.trade(resource: number, quantity: quantity, buying: buying, catalog: archive.catalog)
        }
    }

    func explore(equipmentIndex: Int) {
        edit { world, archive in
            try world.explore(at: world.cursor, equipmentIndex: equipmentIndex, catalog: archive.catalog)
        }
    }

    func process(_ action: Action, objectIndex: Int, equipmentIndex: Int, quantity: Double) {
        edit { world, archive in
            try world.process(action, at: world.cursor, objectIndex: objectIndex,
                              equipmentIndex: equipmentIndex, quantity: quantity, catalog: archive.catalog)
        }
    }

    func produce(_ number: Int, quantity: Double) {
        edit { world, archive in
            try world.produce(number, at: world.cursor, quantity: quantity, catalog: archive.catalog)
        }
    }

    func linkSupply(equipmentIndex: Int, supplyIndex: Int, quantity: Double) {
        edit { world, archive in
            try world.linkSupply(at: world.cursor, equipmentIndex: equipmentIndex, supplyIndex: supplyIndex,
                                 quantity: quantity, catalog: archive.catalog)
        }
    }

    func unlinkSupply(equipmentIndex: Int, supplyIndex: Int) {
        edit { world, archive in
            try world.unlinkSupply(at: world.cursor, equipmentIndex: equipmentIndex, supplyIndex: supplyIndex,
                                   catalog: archive.catalog)
        }
    }

    func transport(vehicleIndex: Int, to destination: Block, mode: TransportMode) {
        edit { world, archive in
            try world.transport(from: world.cursor, to: destination, vehicleIndex: vehicleIndex,
                                mode: mode, catalog: archive.catalog)
        }
    }

    func tick() {
        guard running, sheet == nil else { return }
        edit { world, archive in world.advanceTick(catalog: archive.catalog, using: &random) }
    }

    func advanceUpdate() {
        edit { world, archive in world.advanceToNextUpdate(catalog: archive.catalog, using: &random) }
    }

    func setClockRate(minutes: Int) {
        edit { world, _ in
            world.timeIncrement = GameTime(seconds: min(minutes * 60, world.updateIncrement.totalSeconds))
        }
    }

    func advanceToNextScheduledAction() {
        running = false
        edit { world, archive in
            guard let steps = world.pending.compactMap({ $0.action == nil ? nil : $0.updatesLeft }).min() else { return }
            for _ in 0..<max(1, steps) {
                world.advanceToNextUpdate(catalog: archive.catalog, using: &random)
            }
        }
    }

    private func edit(_ change: (inout World, Archive) throws -> Void) {
        guard var world, let archive else { return }
        do {
            try change(&world, archive)
            self.world = world
            modified = true
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func replaceWorld(_ load: () throws -> Void) {
        guard confirmDiscard("Replace the current world?", button: "Replace World") else { return }
        do { try load() }
        catch { self.error = error.localizedDescription }
    }

    func confirmDiscard(_ message: String, button: String) -> Bool {
        guard modified else { return true }
        running = false
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = "Unsaved colony progress will be lost."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: button)
        return alert.runModal() == .alertSecondButtonReturn
    }

    private func load(_ data: Data) throws {
        try install(LegacyWorld.decode(data), modified: false)
    }

    private func install(_ next: World, modified: Bool) throws {
        let art = try next.picture
        let fullMap = try Archive.image(art, palette: [0x55FF55, 0x55FFFF, 0xFF5555, 0xFFFFFF])
        guard let clipped = fullMap.cropping(to: CGRect(x: 7, y: 8, width: Block.width, height: Block.height)) else {
            throw ArchiveError.binary("cannot crop world map")
        }
        world = next
        map = clipped
        sheet = nil
        error = nil
        running = false
        zoomed = false
        self.modified = modified
    }
}

struct Archive {
    let catalog: ResourceCatalog
    let sampleWorld: Data
    let title: CGImage
    let help: [HelpTopic]
    let scores: [HallOfFameEntry]

    init(bundle: Bundle = .main) throws {
        func data(_ name: String, ext: String = "DAT") throws -> Data {
            guard let path = bundle.url(forResource: name, withExtension: ext) else {
                throw ArchiveError.binary("missing \(name).\(ext) in the app bundle")
            }
            return try Data(contentsOf: path)
        }
        catalog = try ResourceCatalog(data: data("RESOURCE"))
        sampleWorld = try data("VOLTAR")
        title = try Self.image(PackedPicture(data: Array(data("STARFALL", ext: "PIC"))),
                               palette: [0x00AA00, 0x0099AA, 0xAA0000, 0xAAAAAA])
        help = try HelpTopic.decode(index: data("HELPINDX"), pages: data("HELPFILE"))
        scores = try HallOfFameEntry.decode(data("SCORFILE"))
    }

    static func image(_ picture: PackedPicture, palette: [UInt32]) throws -> CGImage {
        let rgba = picture.pixels.flatMap { pixel -> [UInt8] in
            let value = palette[Int(pixel)]
            return [UInt8(truncatingIfNeeded: value >> 16), UInt8(truncatingIfNeeded: value >> 8),
                    UInt8(truncatingIfNeeded: value), 255]
        }
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let image = CGImage(width: picture.width, height: picture.height, bitsPerComponent: 8,
                                  bitsPerPixel: 32, bytesPerRow: picture.width * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            throw ArchiveError.binary("cannot render archived graphics")
        }
        return image
    }
}
