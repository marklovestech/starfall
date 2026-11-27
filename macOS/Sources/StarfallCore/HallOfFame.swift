import Foundation

public struct HallOfFameEntry: Identifiable, Sendable {
    public let rank: Int
    public let name: String
    public let world: String
    public let score: Double
    public var id: Int { rank }

    public static func decode(_ data: Data) throws -> [Self] {
        try HallOfFame(data: data).entries
    }
}

public struct HallOfFame {
    private static let recordCount = 15
    private static let recordSize = 68
    private static let nameCapacity = 30
    private static let worldOffset = nameCapacity + 1
    private static let scoreOffset = 2 * worldOffset
    private static let significandUnit = UInt64(1) << 39
    private var records: [[UInt8]]

    public init(data: Data) throws {
        guard data.count == Self.recordCount * Self.recordSize else {
            throw ArchiveError.binary("invalid SCORFILE.DAT size")
        }
        let bytes = Array(data)
        records = stride(from: 0, to: bytes.count, by: Self.recordSize).map {
            Array(bytes[$0..<($0 + Self.recordSize)])
        }
        guard records.allSatisfy({ $0[0] <= Self.nameCapacity && $0[Self.worldOffset] <= Self.nameCapacity }) else {
            throw ArchiveError.binary("invalid SCORFILE.DAT string length")
        }
    }

    public var data: Data { Data(records.joined()) }

    public var entries: [HallOfFameEntry] {
        records.enumerated().compactMap { index, record in
            let name = Self.readString(record, at: 0)
            guard name != "NONE" else { return nil }
            return HallOfFameEntry(rank: index + 1, name: name,
                                   world: Self.readString(record, at: Self.worldOffset),
                                   score: Self.readScore(record))
        }
    }

    public func rank(for score: Int) -> Int? {
        records.firstIndex { Double(score) >= Self.readScore($0) }.map { $0 + 1 }
    }

    @discardableResult
    public mutating func record(name: String, world: String, score: Int) -> Bool {
        guard let rank = rank(for: score) else { return false }
        // WORLD_RANK_SPOT leaves the last record in CURRENT_SCORE. Pascal short-string
        // assignment overwrites only the length and characters, not the remaining bytes.
        var record = records[Self.recordCount - 1]
        Self.writeString(name, in: &record, at: 0)
        Self.writeString(world, in: &record, at: Self.worldOffset)
        Self.writeScore(score, in: &record)
        records.insert(record, at: rank - 1)
        records.removeLast()
        return true
    }

    private static func readString(_ record: [UInt8], at offset: Int) -> String {
        let start = offset + 1
        return DOSCodePage437.decode(record[start..<(start + Int(record[offset]))])
    }

    private static func writeString(_ value: String, in record: inout [UInt8], at offset: Int) {
        let bytes = DOSCodePage437.encode(value.precomposedStringWithCanonicalMapping).prefix(nameCapacity)
        record[offset] = UInt8(bytes.count)
        record.replaceSubrange((offset + 1)..<(offset + 1 + bytes.count), with: bytes)
    }

    private static func readScore(_ record: [UInt8]) -> Double {
        let exponent = Int(record[scoreOffset])
        guard exponent != 0 else { return 0 }
        let bits = (0..<5).reduce(UInt64(0)) {
            $0 | UInt64(record[scoreOffset + 1 + $1]) << (8 * $1)
        }
        let fraction = Double(bits & (significandUnit - 1)) / Double(significandUnit)
        return Double(sign: bits & significandUnit == 0 ? .plus : .minus,
                      exponent: exponent - 129, significand: 1 + fraction)
    }

    private static func writeScore(_ score: Int, in record: inout [UInt8]) {
        let magnitude = abs(Double(score))
        var exponent = 0
        var bits: UInt64 = 0
        if score != 0 {
            // Turbo Pascal Real48: exponent bias 129, 39 fraction bits and one sign bit.
            exponent = magnitude.exponent + 129
            bits = UInt64(((magnitude.significand - 1) * Double(significandUnit)).rounded(.toNearestOrEven))
            if bits == significandUnit {
                exponent += 1
                bits = 0
            }
            if score < 0 { bits |= significandUnit }
        }
        record[scoreOffset] = UInt8(exponent)
        for index in 0..<5 {
            record[scoreOffset + 1 + index] = UInt8(truncatingIfNeeded: bits >> (8 * index))
        }
    }
}
