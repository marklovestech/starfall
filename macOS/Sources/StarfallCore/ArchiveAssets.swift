import Foundation

public struct PackedPicture: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let pixels: [UInt8]

    public init(data: [UInt8]) throws {
        guard data.count >= 6, data.word(at: 0) == 2 else {
            throw ArchiveError.binary("expected a two-bit Turbo Pascal picture")
        }
        let width = data.word(at: 2) + 1
        let height = data.word(at: 4) + 1
        let stride = (width + 3) / 4
        guard width <= 320, height <= 200, 6 + stride * height <= data.count else {
            throw ArchiveError.binary("invalid picture dimensions")
        }
        self.width = width
        self.height = height
        // Each row is padded to a byte; the first stored row is the bottom one.
        var pixels = [UInt8]()
        pixels.reserveCapacity(width * height)
        for row in (0..<height).reversed() {
            let start = 6 + row * stride
            for x in 0..<width {
                let packed = data[start + x / 4]
                let shift = 6 - 2 * (x % 4)
                pixels.append((packed >> shift) & 3)
            }
        }
        self.pixels = pixels
    }

    public init(width: Int, height: Int, pixels: [UInt8]) {
        precondition(width > 0 && width <= 320 && height > 0 && height <= 200)
        precondition(pixels.count == width * height)
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    public func encodeWords(count: Int) -> [Int16] {
        let stride = (width + 3) / 4
        let byteCount = max(6 + stride * height, count * 2)
        var bytes = [UInt8](repeating: 0, count: byteCount)
        bytes[0] = 2
        bytes[2] = UInt8(truncatingIfNeeded: width - 1)
        bytes[3] = UInt8(truncatingIfNeeded: (width - 1) >> 8)
        bytes[4] = UInt8(truncatingIfNeeded: height - 1)
        bytes[5] = UInt8(truncatingIfNeeded: (height - 1) >> 8)
        for y in 0..<height {
            let start = 6 + (height - 1 - y) * stride
            let rowOffset = y * width
            for x in 0..<width {
                let shift = 6 - 2 * (x % 4)
                bytes[start + x / 4] |= (pixels[rowOffset + x] & 3) << shift
            }
        }
        return (0..<count).map { index in
            let low = UInt16(bytes[index * 2])
            let high = UInt16(bytes[index * 2 + 1]) << 8
            return Int16(bitPattern: low | high)
        }
    }

    public subscript(x: Int, y: Int) -> UInt8 { pixels[y * width + x] }
}

public struct HelpTopic: Identifiable, Sendable {
    public let title: String
    public let pages: [String]
    public var id: String { title }

    public static func decode(index: Data, pages: Data) throws -> [Self] {
        let index = Array(index)
        let pages = Array(pages)
        let indexLength = 55
        let lineLength = 82
        let pageLength = 18 * lineLength
        guard index.count.isMultiple(of: indexLength), pages.count.isMultiple(of: pageLength) else {
            throw ArchiveError.binary("invalid help archive size")
        }
        return try stride(from: 0, to: index.count, by: indexLength).map { offset in
            let title = try index.pascalString(at: offset, capacity: 50)
            let first = index.word(at: offset + 51)
            let last = index.word(at: offset + 53)
            guard first <= last, last < pages.count / pageLength else {
                throw ArchiveError.binary("invalid help page range for \(title)")
            }
            let text = try (first...last).map { page in
                try (0..<18).map { line in
                    try pages.pascalString(at: page * pageLength + line * lineLength + 1, capacity: 80)
                }.joined(separator: "\n")
            }
            return Self(title: title, pages: text)
        }
    }
}

public struct HallOfFameEntry: Identifiable, Sendable {
    public let rank: Int
    public let name: String
    public let world: String
    public let score: Double
    public var id: Int { rank }

    public static func decode(_ data: Data) throws -> [Self] {
        let bytes = Array(data)
        guard bytes.count.isMultiple(of: 68) else { throw ArchiveError.binary("invalid score archive size") }
        return try stride(from: 0, to: bytes.count, by: 68).compactMap { offset in
            let name = try bytes.pascalString(at: offset, capacity: 30)
            guard name != "NONE", !name.isEmpty else { return nil }
            let world = try bytes.pascalString(at: offset + 31, capacity: 30)
            // Real48: base-2 exponent biased by 129, 39 fractional bits, and sign.
            let exponent = Int(bytes[offset + 62])
            let mantissa = (0..<5).reduce(UInt64(0)) { value, index in
                value | UInt64(bytes[offset + 63 + index]) << (index * 8)
            }
            let fraction = Double(mantissa & ((1 << 39) - 1)) / Double(1 << 39)
            let sign = mantissa >> 39 == 0 ? 1.0 : -1.0
            let score = exponent == 0 ? 0 : sign * (1 + fraction) * pow(2, Double(exponent - 129))
            return Self(rank: offset / 68 + 1, name: name, world: world, score: score)
        }
    }
}

private extension Array where Element == UInt8 {
    func word(at index: Int) -> Int { Int(self[index]) | (Int(self[index + 1]) << 8) }

    func pascalString(at index: Int, capacity: Int) throws -> String {
        let count = Int(self[index])
        guard count <= capacity else { throw ArchiveError.binary("invalid Pascal string length") }
        return String(decoding: self[(index + 1)..<(index + 1 + count)], as: UTF8.self)
    }
}
