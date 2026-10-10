import Foundation

// ==========================================
// STARTER DATA (Simulated based on assignment rules)
// ==========================================

typealias Reading = (sensor: String, value: Int)

func splitOnce(_ str: String, by separator: Character) -> (String, String)? {
    guard let index = str.firstIndex(of: separator) else { return nil }
    let left = String(str[..<index])
    let right = String(str[str.index(after: index)...])
    return (left, right)
}

let rawLog: [String] = [
    "02:87", "TEMP:abc", ":55", "RAD:-1", "02:40", "TEMP:-12", "02:50", "TEMP:22",
    "02:90", "TEMP:31", "TEMP:16", "02:-5", "RAD:10", "TEMP:18", "02:100", "02:60"
]

class Tank {
    var level: Int
    init(level: Int) { self.level = level }
}

class Module {
    let name: String
    var oxygenTank: Tank?
    init(name: String, oxygenTank: Tank? = nil) {
        self.name = name
        self.oxygenTank = oxygenTank
    }
}

class CrewMember {
    let name: String
    let role: String
    let priority: Int
    var module: Module?
    
    init(name: String, role: String, priority: Int, module: Module? = nil) {
        self.name = name
        self.role = role
        self.priority = priority
        self.module = module
    }
}

let lab = Module(name: "Lab", oxygenTank: Tank(level: 40))
let hab = Module(name: "Hab", oxygenTank: Tank(level: 12))
let dock = Module(name: "Dock", oxygenTank: nil)

let timur = CrewMember(name: "Timur", role: "Engineer", priority: 3, module: lab)
let dana = CrewMember(name: "Dana", role: "Scientist", priority: 4, module: dock)
let aigerim = CrewMember(name: "Aigerim", role: "Commander", priority: 1, module: hab)
let nurlan = CrewMember(name: "Nurlan", role: "Pilot", priority: 2, module: nil)

let crew: [CrewMember] = [timur, dana, aigerim, nurlan]
let roster: [String: CrewMember] = [
    "Timur": timur, "Dana": dana, "Aigerim": aigerim, "Nurlan": nurlan
]

// ==========================================
// Level 1: Decoding Telemetry
// ==========================================

func parseReading(raw: String) -> Reading? {
    guard let split = splitOnce(raw, by: ":"),
          !split.0.isEmpty,
          let value = Int(split.1),
          value >= 0 || split.0 == "TEMP" else {
        return nil
    }
    return (split.0, value)
}

func parseLog(lines: [String]) -> (valid: [Reading], invalidCount: Int) {
    var valid: [Reading] = []
    var invalidCount = 0
    
    for line in lines {
        if let reading = parseReading(raw: line) {
            valid.append(reading)
        } else {
            invalidCount += 1
        }
    }
    return (valid, invalidCount)
}

let parsedData = parseLog(lines: rawLog)
let A = parsedData.invalidCount

// ==========================================
// Level 2: Analysis
// ==========================================

func select(readings: [Reading], where isIncluded: (Reading) -> Bool) -> [Reading] {
    var filtered: [Reading] = []
    for reading in readings {
        if isIncluded(reading) {
            filtered.append(reading)
        }
    }
    return filtered
}

func values(of readings: [Reading]) -> [Int] {
    var result: [Int] = []
    for reading in readings {
        result.append(reading.value)
    }
    return result
}

let o2Readings = select(readings: parsedData.valid) { $0.sensor == "02" }
let o2Values = values(of: o2Readings)

func stats(of values: [Int]) -> (min: Int, max: Int, average: Double)? {
    guard !values.isEmpty else { return nil }
    
    var min = values[0]
    var max = values[0]
    var sum = 0
    
    for val in values {
        if val < min { min = val }
        if val > max { max = val }
        sum += val
    }
    return (min, max, Double(sum) / Double(values.count))
}

func stats(values: Int...) -> (min: Int, max: Int, average: Double)? {
    stats(of: values)
}

let o2Stats = stats(of: o2Values)
let B = Int(o2Stats?.average ?? 0)

// ==========================================
// Level 3: Temperature Stabilization
// ==========================================

func heatUp(_ temp: Int) -> Int { temp + 5 }
func coolDown(_ temp: Int) -> Int { temp - 3 }
func hold(_ temp: Int) -> Int { temp }

func chooseProtocol(for temp: Int) -> (Int) -> Int {
    if temp < 18 { return heatUp }
    if temp > 24 { return coolDown }
    return hold
}

func runUntilStable(from start: Int, maxSteps: Int = 10) -> (finalTemp: Int, steps: Int, isStable: Bool) {
    var currentTemp = start
    var steps = 0
    
    while (currentTemp < 18 || currentTemp > 24) && steps < maxSteps {
        let action = chooseProtocol(for: currentTemp)
        currentTemp = action(currentTemp)
        steps += 1
    }
    
    return (currentTemp, steps, currentTemp >= 18 && currentTemp <= 24)
}

let tempReadings = select(readings: parsedData.valid) { $0.sensor == "TEMP" }
let tempValues = values(of: tempReadings)
let minTemp = stats(of: tempValues)?.min ?? 0
let C = runUntilStable(from: minTemp).steps

// ==========================================
// Level 4: The Crew
// ==========================================

func oxygenLevel(of member: CrewMember) -> Int? {
    member.module?.oxygenTank?.level
}

func status(of member: CrewMember) -> String {
    guard let module = member.module else {
        return "\(member.name): no data (open space)"
    }
    
    guard let level = oxygenLevel(of: member) else {
        return "\(member.name): no data (\(module.name))"
    }
    
    return level < 20 ? "\(member.name): \(level)% CRITICAL" : "\(member.name): \(level)% OK"
}

@discardableResult
func transferOxygen(from source: inout Int, to target: inout Int, amount: Int) -> Int {
    guard amount > 0 else { return 0 }
    
    let availableToTake = min(source, amount)
    let availableSpace = 100 - target
    let actualTransfer = min(availableToTake, availableSpace)
    
    source -= actualTransfer
    target += actualTransfer
    
    return actualTransfer
}

var labTankLevel = lab.oxygenTank?.level ?? 0
var habTankLevel = hab.oxygenTank?.level ?? 0
transferOxygen(from: &labTankLevel, to: &habTankLevel, amount: 30)
lab.oxygenTank?.level = labTankLevel
hab.oxygenTank?.level = habTankLevel
let D = habTankLevel

func evacuationOrder(names: String..., roster: [String: CrewMember]) -> [String] {
    var foundMembers: [CrewMember] = []
    
    for name in names {
        guard let member = roster[name] else {
            print("Unknown crew member: \(name)")
            continue
        }
        foundMembers.append(member)
    }
    
    var resultNames: [String] = []
    for member in foundMembers.sorted(by: { $0.priority < $1.priority }) {
        resultNames.append(member.name)
    }
    
    return resultNames
}

// ==========================================
// Finale: The Launch Code
// ==========================================
let launchCode = "\(A)-\(B)-\(C)-\(D)"
print("LAUNCH CODE: \(launchCode)")

