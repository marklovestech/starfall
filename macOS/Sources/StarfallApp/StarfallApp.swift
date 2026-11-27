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
                Button("Open World…", action: game.open)
                    .keyboardShortcut("o")
                Button("Load Voltar", action: game.loadVoltar)
                    .keyboardShortcut("n")
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
        game?.endGame(quitting: true) == false ? .terminateCancel : .terminateNow
    }
}

@MainActor @Observable
final class GameSession {
    enum Sheet: String, Identifiable {
        case instructions, scores, inventory, pending, log, trade, block
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
    private(set) var scores: [HallOfFameEntry] = []
    private var random = SystemRandomNumberGenerator()
    private let scoreFile = URL.applicationSupportDirectory.appending(path: "Starfall/SCORFILE.DAT")

    init() {
        do { archive = try Archive() }
        catch { self.error = error.localizedDescription }
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

    func showScores() {
        guard let archive else { return }
        do {
            scores = try readScores(archive).entries
            error = nil
            sheet = .scores
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func readScores(_ archive: Archive) throws -> HallOfFame {
        do {
            return try HallOfFame(data: Data(contentsOf: scoreFile))
        } catch CocoaError.fileReadNoSuchFile {
            return archive.seedScores
        }
    }

    @discardableResult
    func endGame(quitting: Bool = false) -> Bool {
        guard let world, let archive else { return true }
        running = false
        let confirm = NSAlert()
        confirm.messageText = quitting ? "Quit Starfall and end this game?" : "End this game?"
        confirm.informativeText = modified ? "Unsaved colony progress will be lost." : "The colony’s final score will be calculated."
        confirm.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
        confirm.addButton(withTitle: quitting ? "Quit" : "End Game")
        guard confirm.runModal() == .alertSecondButtonReturn else { return false }

        let score = world.finalScore(catalog: archive.catalog)
        do {
            var hall = try readScores(archive)
            if let rank = hall.rank(for: score) {
                let prompt = NSAlert()
                prompt.messageText = "You made the Hall of Fame!"
                prompt.informativeText = "Your final score of \(score.formatted()) ranks #\(rank). Enter your name (up to 30 DOS characters)."
                let name = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
                name.placeholderString = "Colonist name"
                name.setAccessibilityLabel("Colonist name")
                prompt.accessoryView = name
                prompt.window.initialFirstResponder = name
                prompt.addButton(withTitle: "Record Score")
                prompt.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
                guard prompt.runModal() == .alertFirstButtonReturn else { return false }

                hall.record(name: name.stringValue, world: world.name, score: score)
                try FileManager.default.createDirectory(at: scoreFile.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                try hall.data.write(to: scoreFile, options: .atomic)
                scores = hall.entries
                discardWorld()
                if !quitting { sheet = .scores }
            } else {
                discardWorld()
            }
            return true
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Could not save your Hall of Fame score."
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
            discardWorld()
            return true
        }
    }

    private func discardWorld() {
        world = nil
        map = nil
        sheet = nil
        error = nil
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

    private func confirmDiscard(_ message: String, button: String) -> Bool {
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
        let next = try LegacyWorld.decode(data)
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
        modified = false
    }
}

struct Archive {
    let catalog: ResourceCatalog
    let sampleWorld: Data
    let title: CGImage
    let help: [HelpTopic]
    let seedScores: HallOfFame

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
        seedScores = try HallOfFame(data: data("SCORFILE"))
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
