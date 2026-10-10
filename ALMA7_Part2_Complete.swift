import Foundation

// ==========================================
// STARTER DATA (Simulated based on assignment rules)
// ==========================================
func fields(_ line: String, separatedBy separator: Character) -> [String] {
    return line.split(separator: separator).map { String($0) }
}

let rawManifest: [String] = [
    "crate:101:120",
    "container:KZ-ALM-7:340",
    "livestock:lab mice:12:2",
    "unknown_tag:xyz:100",
    "crate:102:invalid",
    "crate:103:50",
    "container:US-ALM-7:200",
    "livestock:chickens:50:3",
    "crate:104:80",
    "container:EU-ALM-7:150"
]

let deckReadings: [(deck: String, oxygen: Int)] = [
    ("bridge", 98),
    ("lab", 95),
    ("cargo", 99),
    ("medbay", 100),
    ("engine", 90),
    ("fake_deck", 50)
]

let crewData: [(name: String, deck: String, oxygen: Int)] = [
    ("Timur", "lab", 85),
    ("Dana", "bridge", 90),
    ("Aigerim", "medbay", 100),
    ("Nurlan", "engine", 70)
]

// ==========================================
// Level 1: The Deck Register
// ==========================================
enum Deck: String, CaseIterable {
    case bridge, lab, cargo, medbay, engine
    
    var evacuationPriority: Int {
        switch self {
        case .bridge: return 1
        case .medbay: return 2
        case .lab: return 3
        case .engine: return 4
        case .cargo: return 5
        }
    }
}

for deck in Deck.allCases {
    print("\(deck.rawValue): priority \(deck.evacuationPriority)")
}

enum AlarmLevel: Int {
    case green = 0, yellow, orange, red
    
    static func level(forTotalMass mass: Int) -> AlarmLevel {
        let step = mass / 500
        let raw = step >= 3 ? 3 : step
        return AlarmLevel(rawValue: raw) ?? .red
    }
}

// ==========================================
// Level 2: The Manifest
// ==========================================
enum ManifestEntry {
    case crate(id: Int, massKg: Int)
    case container(code: String, massKg: Int)
    case livestock(species: String, count: Int, massPerUnitKg: Int)
    case unknown(raw: String)
}

func parseEntry(line: String) -> ManifestEntry {
    let parts = fields(line, separatedBy: ":")
    
    if parts.count > 0 {
        let tag = parts[0]
        if tag == "crate", parts.count == 3, let id = Int(parts[1]), let mass = Int(parts[2]) {
            return .crate(id: id, massKg: mass)
        } else if tag == "container", parts.count == 3, let mass = Int(parts[2]) {
            return .container(code: parts[1], massKg: mass)
        } else if tag == "livestock", parts.count == 4, let count = Int(parts[2]), let mass = Int(parts[3]) {
            return .livestock(species: parts[1], count: count, massPerUnitKg: mass)
        }
    }
    return .unknown(raw: line)
}

func mass(of entry: ManifestEntry) -> Int {
    switch entry {
    case .crate(_, let massKg): return massKg
    case .container(_, let massKg): return massKg
    case .livestock(_, let count, let massPerUnitKg): return count * massPerUnitKg
    case .unknown: return 0
    }
}

var totalManifestMass = 0
var unknownCount = 0
for line in rawManifest {
    let entry = parseEntry(line: line)
    totalManifestMass += mass(of: entry)
    if case .unknown = entry {
        unknownCount += 1
    }
}
print("Unknown lines: \(unknownCount)")
let A = totalManifestMass

// ==========================================
// Level 3: Crew Snapshots
// ==========================================
struct CrewSnapshot {
    let name: String
    var deck: Deck
    var oxygen: Int
    
    mutating func breathe(amount: Int) {
        oxygen -= amount
        if oxygen < 0 { oxygen = 0 }
    }
    
    mutating func move(to newDeck: Deck) {
        deck = newDeck
    }
    
    mutating func reviveInMedbay() {
        self = CrewSnapshot(name: self.name, deck: .medbay, oxygen: 100)
    }
    
    static func rookie(named name: String) -> CrewSnapshot {
        return CrewSnapshot(name: name, deck: .bridge, oxygen: 100)
    }
}

var roster: [CrewSnapshot] = []
for data in crewData {
    if let deck = Deck(rawValue: data.deck) {
        roster.append(CrewSnapshot(name: data.name, deck: deck, oxygen: data.oxygen))
    } else {
        print("Warning: Unknown deck '\(data.deck)' for \(data.name)")
    }
}

var snapshot1 = CrewSnapshot.rookie(named: "Test1")
var snapshot2 = snapshot1
snapshot2.move(to: .lab)
print("1. Copy modified: \(snapshot2.deck), Original unchanged: \(snapshot1.deck)")

func plainFunction(snap: CrewSnapshot) {
    var copy = snap
    copy.breathe(amount: 10)
}
plainFunction(snap: snapshot1)
print("2. Passed to plain func, Original unchanged: \(snapshot1.oxygen)")

func inoutFunction(snap: inout CrewSnapshot) {
    snap.breathe(amount: 10)
}
inoutFunction(snap: &snapshot1)
print("3. Passed as inout, Original changed: \(snapshot1.oxygen)")

// ==========================================
// Level 4: The Teleport Pod
// ==========================================
final class TeleportPod {
    let id: String
    var chargeLevel: Int
    var occupant: CrewSnapshot?
    
    init(id: String, chargeLevel: Int) {
        self.id = id
        self.chargeLevel = chargeLevel
        self.occupant = nil
    }
    
    func load(crew: CrewSnapshot) -> Bool {
        if occupant != nil || chargeLevel < 20 { return false }
        occupant = crew
        return true
    }
    
    func fire() -> CrewSnapshot? {
        guard let crew = occupant, chargeLevel >= 20 else { return nil }
        chargeLevel -= 20
        occupant = nil
        return crew
    }
}

let pod = TeleportPod(id: "P-1", chargeLevel: 100)
if pod.load(crew: CrewSnapshot.rookie(named: "Timur")) { _ = pod.fire() }
print("Charge after Timur: \(pod.chargeLevel)")
if pod.load(crew: CrewSnapshot.rookie(named: "Dana")) { _ = pod.fire() }
print("Charge after Dana: \(pod.chargeLevel)")
if pod.load(crew: CrewSnapshot.rookie(named: "Nurlan")) { _ = pod.fire() }
print("Charge after Nurlan: \(pod.chargeLevel)")
_ = pod.fire()
print("Charge after empty fire: \(pod.chargeLevel)")
let C = pod.chargeLevel

let podCopy = pod
podCopy.chargeLevel = 10
print("Original pod charge: \(pod.chargeLevel), Copied pod charge: \(podCopy.chargeLevel)")

// ==========================================
// Level 5: Station Systems
// ==========================================
class Station {
    let callSign: String
    
    var hullIntegrity: Int {
        willSet {
            print("Integrity changing from \(hullIntegrity) to \(newValue)")
        }
        didSet {
            if hullIntegrity < 0 { hullIntegrity = 0 }
            if hullIntegrity > 100 { hullIntegrity = 100 }
        }
    }
    
    lazy var fullDiagnostics: String = {
        print("Running full scan...")
        return "All systems nominal."
    }()
    
    var oxygenByDeck: [Deck: Int] = [:]
    
    var totalOxygen: Int {
        var sum = 0
        for value in oxygenByDeck.values { sum += value }
        return sum
    }
    
    var averageOxygen: Int {
        get {
            if oxygenByDeck.isEmpty { return 0 }
            return totalOxygen / oxygenByDeck.count
        }
        set {
            for key in oxygenByDeck.keys {
                oxygenByDeck[key] = newValue
            }
        }
    }
    
    init(callSign: String, initialIntegrity: Int) {
        self.callSign = callSign
        self.hullIntegrity = initialIntegrity
    }
}

let station = Station(callSign: "ALMA-7", initialIntegrity: 100)
for reading in deckReadings {
    if let deck = Deck(rawValue: reading.deck) {
        station.oxygenByDeck[deck] = reading.oxygen
    }
}
let B = station.averageOxygen

station.hullIntegrity = 130
print("Integrity: \(station.hullIntegrity)") // 100
station.hullIntegrity = 40
print("Integrity: \(station.hullIntegrity)") // 40
station.hullIntegrity = 55
print("Integrity: \(station.hullIntegrity)") // 55

// ==========================================
// Level 6: Incident Reports
// ==========================================
for i in 0..<roster.count {
    roster[i].oxygen = 10
}

let podA = TeleportPod(id: "A", chargeLevel: 100)
let podB = TeleportPod(id: "B", chargeLevel: 100)
podB.chargeLevel = 0

struct Logbook {
    var entries: [String] = []
    mutating func add(entry: String) { entries.append(entry) }
}

var snapshot = CrewSnapshot.rookie(named: "Dana")
snapshot.oxygen = 40
let podRef = TeleportPod(id: "B", chargeLevel: 50)
podRef.chargeLevel = 10

// ==========================================
// Level 7: Sealing the Black Box
// ==========================================
class FlightRecorder {
    private(set) var entries: [String] = []
    private(set) var isSealed = false
    fileprivate var accessCount = 0
    
    var entryCount: Int { entries.count }
    
    func add(entry: String) {
        guard !isSealed else { return }
        entries.append(entry)
        accessCount += 1
    }
    
    func seal() { isSealed = true }
    
    func transcript() -> String {
        return entries.joined(separator: "\n")
    }
}

// ==========================================
// Finale: The Integrity Code
// ==========================================
let D = AlarmLevel.level(forTotalMass: A).rawValue
let integrityCode = "\(A)-\(B)-\(C)-\(D)"
print("INTEGRITY CODE: \(integrityCode)")
