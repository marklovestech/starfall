import Foundation

public struct Resource: Identifiable, Sendable {
    struct Need: Sendable {
        let number: Int
        let quantity: Double
    }

    struct Ingredient: Sendable {
        let number: Int
        let quantity: Double
        let timeFactor: Double
        var alternatives: [Ingredient]
    }

    public let id: Int
    public let name: String
    public let units: String
    public let scoreValue: Int
    public let baseCost: Double
    let weight: Double
    let movable: Bool
    public let naturallyOccurring: Bool
    public let typicalTraderAmount: Double
    let expendable: Bool
    let purity: Double
    let basic: [Need]
    let active: [Need]
    let explores: Bool
    let explorationSpeed: Double
    let tests: [Int]
    let extracts: Bool
    let extractable: Bool
    let extractionSpeed: Double
    let develops: Bool
    let developmentSpeed: Double
    let developable: Bool
    let developmentResult: Int
    let developmentEquipment: ClosedRange<Int>?
    let refines: Bool
    let refinementSpeed: Double
    let refinable: Bool
    let refinementResult: Int
    let refinementEquipment: ClosedRange<Int>?
    let transports: Bool
    let cargoCapacity: Double
    let airSpeed: Double
    let landSpeed: Double
    let waterSpeed: Double
    public let producible: Bool
    let productionTime: Double
    let recipe: [Ingredient]

    public var purchasePrice: Double { baseCost * 1.05 }
    public var salePrice: Double { baseCost * 0.95 }
}

public struct ResourceCatalog: Sendable {
    public let resources: [Resource]

    public subscript(number: Int) -> Resource? {
        (1...resources.count).contains(number) ? resources[number - 1] : nil
    }

    public init(data: Data) throws {
        var reader = try PascalText(data)
        resources = try (1...255).map { number in
            let name = try reader.string()
            let units = try reader.string()
            let score = try reader.integer()
            let cost = try reader.real()
            let weight = try reader.real()
            let natural = try reader.boolean()
            _ = try reader.boolean() // Subsurface
            let expendable = try reader.boolean()
            let movable = try reader.boolean()
            let amount = try reader.real()
            let purity = try reader.real()
            let basic = try Self.needs(&reader)
            let active = try Self.needs(&reader)
            let explores = try reader.boolean()
            let explorationSpeed = try reader.real()
            let tests = try (0..<4).map { _ in try reader.integer() }
            let extracts = try reader.boolean()
            let extractionSpeed = try reader.real()
            let extractable = try reader.boolean()
            for _ in 0..<3 { _ = try reader.real() } // Deposit distribution
            let develops = try reader.boolean()
            let developmentSpeed = try reader.real()
            let developable = try reader.boolean()
            let development = try reader.integer(0...255)
            let developmentEquipment = try Self.equipmentRange(&reader)
            let refines = try reader.boolean()
            let refinementSpeed = try reader.real()
            let refinable = try reader.boolean()
            let refinement = try reader.integer(0...255)
            let refinementEquipment = try Self.equipmentRange(&reader)
            let transports = try reader.boolean()
            let capacity = try reader.real()
            let airSpeed = try reader.real()
            let landSpeed = try reader.real()
            let waterSpeed = try reader.real()
            let producible = try reader.boolean()
            let productionTime = try reader.real()
            let recipe: [Resource.Ingredient] = try reader.tree { reader in
                try Resource.Ingredient(number: reader.integer(0...255), quantity: reader.real(),
                                        timeFactor: reader.real(), alternatives: [])
            } attach: { $0.alternatives = $1 }
            return Resource(id: number, name: name, units: units, scoreValue: score,
                            baseCost: cost, weight: weight, movable: movable, naturallyOccurring: natural, typicalTraderAmount: amount,
                            expendable: expendable, purity: purity, basic: basic, active: active,
                            explores: explores, explorationSpeed: explorationSpeed, tests: tests,
                            extracts: extracts, extractable: extractable, extractionSpeed: extractionSpeed, develops: develops,
                            developmentSpeed: developmentSpeed, developable: developable,
                            developmentResult: development, developmentEquipment: developmentEquipment,
                            refines: refines, refinementSpeed: refinementSpeed, refinable: refinable,
                            refinementResult: refinement, refinementEquipment: refinementEquipment,
                            transports: transports, cargoCapacity: capacity, airSpeed: airSpeed, landSpeed: landSpeed,
                            waterSpeed: waterSpeed,
                            producible: producible, productionTime: productionTime, recipe: recipe)
        }
        guard reader.atEnd else { throw reader.error("end of resource catalog") }
    }

    private static func needs(_ reader: inout PascalText) throws -> [Resource.Need] {
        let numbers = try (0..<4).map { _ in try reader.integer(0...255) }
        return try numbers.map { try Resource.Need(number: $0, quantity: reader.real()) }.filter { $0.number != 0 }
    }

    private static func equipmentRange(_ reader: inout PascalText) throws -> ClosedRange<Int>? {
        let lower = try reader.integer(0...255)
        let upper = try reader.integer(0...255)
        if upper == 0 { return lower...255 }
        return lower <= upper ? lower...upper : nil
    }
}
