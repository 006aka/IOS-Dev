import Foundation

// ==========================================
// STARTER DATA (Simulated)
// ==========================================

let fleetData: [(kind: String, id: String, charge: Int)] = [
    ("welder", "W-1", 100),
    ("scanner", "S-1", 100),
    ("cargo", "C-1", 100),
    ("welder", "W-2", 40),
    ("fake_drone", "F-1", 100),
    ("scanner", "S-2", 15)
]

let sensorData: [(id: String, charge: Int)] = [
    ("HULL-1", 100),
    ("HULL-2", 10)
]

struct LegacyBeacon {
    let id: String
    var signalStrength: Int
}
var beacon = LegacyBeacon(id: "BEACON-ALPHA", signalStrength: 45)

// ==========================================
// Level 1: The Power Cell
// ==========================================
// Why a class? Because a power cell represents a shared, mutable resource (reference type) whose state changes need to be reflected wherever it's referenced.
final class PowerCell {
    private var charge: Int
    
    init(charge: Int) {
        if charge < 0 { self.charge = 0 }
        else if charge > 100 { self.charge = 100 }
        else { self.charge = charge }
    }
    
    func level() -> Int {
        return charge
    }
    
    func spend(amount: Int) -> Bool {
        if amount <= 0 || charge < amount { return false }
        charge -= amount
        return true
    }
    
    func recharge(by amount: Int) {
        if amount <= 0 { return }
        charge += amount
        if charge > 100 { charge = 100 }
    }
}

// let testCell = PowerCell(charge: 100)
// testCell.charge = 100
// Compiler error: 'charge' is inaccessible due to 'private' protection level

// ==========================================
// Level 5.3: Extending Int for powerBar
// ==========================================
extension Int {
    var powerBar: String {
        let clamped = max(0, min(10, self / 10))
        let hashes = String(repeating: "#", count: clamped)
        let dots = String(repeating: ".", count: 10 - clamped)
        return hashes + dots
    }
}

// ==========================================
// Level 4: Diagnostics Protocols
// ==========================================
protocol Diagnosable {
    var componentID: String { get }
    var statusCode: Int { get }
    func diagnose() -> String
}

protocol Rechargeable {
    mutating func recharge(by amount: Int)
}

// ==========================================
// Level 5.1: The Rule Lives in the Protocol
// ==========================================
extension Diagnosable {
    func diagnose() -> String {
        return "\(componentID): code \(statusCode)"
    }
    
    func calculateStatusCode(from value: Int) -> Int {
        if value < 20 { return 2 }
        if value < 50 { return 1 }
        return 0
    }
}

// ==========================================
// Level 2: The Fleet & Protocols Application
// ==========================================
class Drone: Diagnosable, Rechargeable {
    let id: String
    let cell: PowerCell
    
    init(id: String, cell: PowerCell) {
        self.id = id
        self.cell = cell
    }
    
    var powerCost: Int { 10 }
    
    var statusLine: String {
        return "\(id): \(cell.level())% [\(cell.level().powerBar)]"
    }
    
    func performTask() -> Int { 0 }
    
    // final prevents subclasses from altering the shift ritual (spending power before working), ensuring the core logic is never bypassed.
    final func runOnce() -> Int {
        if cell.spend(amount: powerCost) {
            return performTask()
        }
        return 0
    }
    
    // Diagnosable
    var componentID: String { return id }
    var statusCode: Int { return calculateStatusCode(from: cell.level()) }
    
    // Rechargeable
    // A class doesn't need 'mutating' because reference types mutate in place without replacing the instance itself.
    func recharge(by amount: Int) {
        cell.recharge(by: amount)
    }
}

final class WelderDrone: Drone {
    override var powerCost: Int { 25 }
    override func performTask() -> Int { 40 }
    func weldSeam() -> String { return "Seam welded" }
}

class ScannerDrone: Drone {
    override var powerCost: Int { 10 }
    override func performTask() -> Int { 15 }
    override var statusLine: String {
        return super.statusLine + " [scanner]"
    }
}

final class CargoDrone: Drone {
    override var powerCost: Int { 20 }
    override func performTask() -> Int { 25 }
}

func makeDrone(kind: String, id: String, charge: Int) -> Drone? {
    let cell = PowerCell(charge: charge)
    switch kind {
    case "welder": return WelderDrone(id: id, cell: cell)
    case "scanner": return ScannerDrone(id: id, cell: cell)
    case "cargo": return CargoDrone(id: id, cell: cell)
    default: return nil
    }
}

var fleet: [Drone] = []
for data in fleetData {
    if let drone = makeDrone(kind: data.kind, id: data.id, charge: data.charge) {
        fleet.append(drone)
    } else {
        print("Warning: Skipped unknown drone kind '\(data.kind)' for ID \(data.id)")
    }
}

// ==========================================
// Level 3: The Shift
// ==========================================
func runShift(fleet: [Drone], rounds: Int) -> Int {
    var totalWork = 0
    for _ in 0..<rounds {
        for drone in fleet {
            totalWork += drone.runOnce()
        }
    }
    return totalWork
}

let A = runShift(fleet: fleet, rounds: 3)

var B = 0
var C = 0
for drone in fleet {
    print(drone.statusLine)
    B += drone.cell.level()
    if drone.cell.level() >= drone.powerCost {
        C += 1
    }
}

// ==========================================
// Level 4: Diagnostics
// ==========================================
struct SensorModule: Diagnosable, Rechargeable {
    let id: String
    var chargeLevel: Int
    
    var componentID: String { return id }
    var statusCode: Int { return calculateStatusCode(from: chargeLevel) }
    
    mutating func recharge(by amount: Int) {
        if amount > 0 {
            chargeLevel = min(100, chargeLevel + amount)
        }
    }
}

// ==========================================
// Level 5.2: The Legacy Beacon
// ==========================================
extension LegacyBeacon: Diagnosable {
    var componentID: String { return id }
    var statusCode: Int { return calculateStatusCode(from: signalStrength) }
    
    func diagnose() -> String {
        return "LEGACY HARDWARE [\(componentID)]: code \(statusCode)"
    }
}

func diagnosticsReport(components: [Diagnosable]) -> String {
    // [Drone] can't hold sensors because sensors are structs, not subclasses of the Drone class. Protocols allow grouping disparate types.
    var report = ""
    for component in components {
        report += component.diagnose() + "\n"
    }
    return report
}

var allComponents: [Diagnosable] = []
for drone in fleet { allComponents.append(drone) }
for sData in sensorData { allComponents.append(SensorModule(id: sData.id, chargeLevel: sData.charge)) }
allComponents.append(beacon)

print("\nDIAGNOSTICS REPORT:")
print(diagnosticsReport(components: allComponents))

var D = 0
for component in allComponents {
    D += component.statusCode
}

// ==========================================
// Level 6: Incident Reports
// ==========================================
/*
// Report 1
// Expected: PatchDrone performs 30 work. Actually: Compiler error.
// Rule: You must use the `override` keyword when replacing a superclass method.
class PatchDrone: Drone {
    override func performTask() -> Int { return 30 }
}

// Report 2
// Expected: HeavyWelder overrides runOnce to return 999. Actually: Compiler error.
// Rule: `runOnce` is marked `final` in the base class, meaning it cannot be overridden. `WelderDrone` itself is also `final`.
// Fix: Remove the class or change what it overrides (like performTask).

// Report 3
// Expected: fleet[0].weldSeam() works. Actually: Compiler error because `fleet` is typed as `[Drone]`, which doesn't have `weldSeam`.
// Rule: Polymorphism hides subclass specifics. `as?` returns an optional because the downcast might fail at runtime if the object isn't actually a WelderDrone.
let fleet3: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
if let welder = fleet3[0] as? WelderDrone {
    print(welder.weldSeam())
}

// Report 4
// Expected: "thruster T-1". Actually: "generic component".
// Rule: If a method is NOT defined in the protocol itself (only in the extension), Swift uses static dispatch (type of the variable `Labelled`). If defined in the protocol, it uses dynamic dispatch (type of the instance `Thruster`).
// Fix: Add `func label() -> String` inside the `protocol Labelled { ... }` block.
protocol Labelled {
    var componentID: String { get }
    func label() -> String // <-- THE FIX
}
extension Labelled {
    func label() -> String { "generic component" }
}
struct Thruster: Labelled {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}
let parts: [Labelled] = [Thruster(componentID: "T-1")]
print(parts[0].label())
*/

// ==========================================
// Finale: The Mission Code
// ==========================================
let missionCode = "\(A)-\(B)-\(C)-\(D)"
print("\nMISSION CODE: \(missionCode)")

// ==========================================
// Defense Questions
// ==========================================
/*
1. Classes are reference types; their properties can be mutated without replacing the object itself, so `mutating` isn't required. Structs are value types and replacing their properties effectively replaces the whole instance, requiring `mutating`.
2. Inheritance allows sharing of stored properties (state) and default method implementations through a base class. Protocols allow unrelated types (classes, structs, enums) to conform to a shared interface, which inheritance cannot do.
3. `final` prevents a class from being subclassed, or a method/property from being overridden. Making `runOnce()` final protected the core shift ritual (checking and spending power) from being bypassed or altered by a subclass.
4. Because `label()` was only in the protocol extension (not a requirement in the protocol definition), the compiler used static dispatch based on the variable's type (`Labelled`), invoking the generic version instead of dynamic dispatch which would check the actual instance type at runtime.
*/
