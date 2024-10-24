import Foundation

final class Storage {
    private let userDefaults = UserDefaults.standard
    
    var previoudOrderId: Int? {
        get {
            userDefaults.object(forKey: Keys.previousOrderId.key) as? Int
        } set {
            userDefaults.set(newValue, forKey: Keys.previousOrderId.key)
        }
    }
    
    func cleanCache() {
        Keys.allCases.forEach {
            userDefaults.removeObject(forKey: $0.key)
        }
    }
}

fileprivate extension Storage {
    enum Keys: String, CaseIterable {
        case previousOrderId = "app.prev.order.id"
        
        var key: String { rawValue }
    }
}
