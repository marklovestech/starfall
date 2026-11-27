import Foundation

public enum ArchiveError: LocalizedError {
    case line(Int, String)
    case binary(String)

    public var errorDescription: String? {
        switch self {
        case let .line(number, expected): "Invalid Starfall data at line \(number): expected \(expected)."
        case let .binary(message): "Invalid Starfall data: \(message)."
        }
    }
}

struct PascalText {
    private let lines: [Substring]
    private var index = 0
    var atEnd: Bool { index == lines.count }

    init(_ data: Data) throws {
        guard data.count <= 16 * 1_024 * 1_024 else { throw ArchiveError.binary("file is too large") }
        let body = data.prefix { $0 != 26 }
        let text = DOSCodePage437.decode(body)
        var split = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        if split.last?.isEmpty == true { split.removeLast() }
        lines = split
    }

    func error(_ expected: String) -> ArchiveError { .line(max(1, index), expected) }

    mutating func string() throws -> String {
        guard !atEnd else { throw ArchiveError.line(index + 1, "another line") }
        defer { index += 1 }
        return String(lines[index])
    }

    mutating func integer(_ range: ClosedRange<Int> = -32_768...32_767) throws -> Int {
        guard let number = Int(try string().trimmingCharacters(in: .whitespaces)), range.contains(number) else {
            throw error("integer in \(range)")
        }
        return number
    }

    mutating func real() throws -> Double {
        guard let number = Double(try string().trimmingCharacters(in: .whitespaces)), number.isFinite else {
            throw error("finite number")
        }
        return number
    }

    mutating func boolean() throws -> Bool {
        switch try string() {
        case "T": true
        case "F": false
        default: throw error("T or F")
        }
    }

    mutating func hasRecord() throws -> Bool {
        switch try string() {
        case "DATA": true
        case "NIL": false
        default: throw error("DATA or NIL")
        }
    }

    mutating func time() throws -> GameTime {
        try GameTime(
            day: integer(), month: integer(), year: integer(), second: integer(), minute: integer(), hour: integer()
        )
    }

    mutating func block() throws -> Block {
        try Block(x: integer(1...Block.width), y: integer(1...Block.height))
    }

    // The Pascal record writes a sibling before its children, so read the whole sibling chain
    // first. Its child trees then appear in reverse order as the Pascal calls unwind.
    mutating func tree<Node>(depth: Int = 0, read: (inout Self) throws -> Node,
                             attach: (inout Node, [Node]) -> Void) throws -> [Node] {
        guard depth < 256 else { throw error("a shallower resource tree") }
        var siblings = [Node]()
        while try hasRecord() { siblings.append(try read(&self)) }
        for i in siblings.indices.reversed() {
            let children = try tree(depth: depth + 1, read: read, attach: attach)
            attach(&siblings[i], children)
        }
        return siblings
    }

    mutating func stock() throws -> [Stock] {
        try tree { reader in
            try Stock(number: reader.integer(1...255), quantity: reader.real(),
                      flags: UInt8(reader.integer(0...255)), contents: [])
        } attach: { $0.contents = $1 }
    }

    mutating func list<Element>(_ read: (inout Self) throws -> Element) throws -> [Element] {
        var items = [Element]()
        while try hasRecord() { items.append(try read(&self)) }
        return items
    }
}

enum DOSCodePage437 {
    private static let extended = Array([
        "ÇüéâäàåçêëèïîìÄÅ",
        "ÉæÆôöòûùÿÖÜ¢£¥₧ƒ",
        "áíóúñÑªº¿⌐¬½¼¡«»",
        "░▒▓│┤╡╢╖╕╣║╗╝╜╛┐",
        "└┴┬├─┼╞╟╚╔╩╦╠═╬╧",
        "╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀",
        "αßΓπΣσµτΦΘΩδ∞φε∩",
        "≡±≥≤⌠⌡÷≈°∙·√ⁿ²■\u{00A0}",
    ].joined().unicodeScalars)
    private static let encoded = Dictionary(uniqueKeysWithValues: extended.enumerated().map {
        ($0.element, UInt8($0.offset + 128))
    })

    static func decode(_ bytes: some Collection<UInt8>) -> String {
        if bytes.allSatisfy({ $0 < 128 }) { return String(decoding: bytes, as: UTF8.self) }
        var text = String.UnicodeScalarView()
        for byte in bytes {
            text.append(byte < 128 ? UnicodeScalar(byte) : extended[Int(byte) - 128])
        }
        return String(text)
    }

    static func encode(_ text: String) -> Data {
        if text.utf8.allSatisfy({ $0 < 128 }) { return Data(text.utf8) }
        return Data(text.unicodeScalars.map {
            $0.value < 128 ? UInt8($0.value) : encoded[$0] ?? 63
        })
    }
}
