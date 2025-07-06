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
    
    var opKey: String? {
        get {
            userDefaults.object(forKey: Keys.opKey.key) as? String
        } set {
            userDefaults.set(newValue, forKey: Keys.opKey.key)
        }
    }
    
    var hasShownSuccessPayment: Bool? {
        get {
            userDefaults.object(forKey: Keys.hasShownSuccessPayment.key) as? Bool
        } set {
            userDefaults.set(newValue, forKey: Keys.hasShownSuccessPayment.key)
        }
    }

    var bodyStringForCheckStatusUrl: String? {
        get {
            userDefaults.object(forKey: Keys.bodyStringForCheckStatusUrl.key) as? String
        } set {
            userDefaults.set(newValue, forKey: Keys.bodyStringForCheckStatusUrl.key)
        }
    }

    var currentInvoiceId: Int? {
        get {
            userDefaults.object(forKey: Keys.currentInvoiceId.key) as? Int
        } set {
            userDefaults.set(newValue, forKey: Keys.currentInvoiceId.key)
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
        case opKey = "app.op.key"
        case hasShownSuccessPayment = "app.has.shown.success.payment"
        case bodyStringForCheckStatusUrl = "app.body.string.for.check.status.url"
        case currentInvoiceId = "app.current.invoice.id"

        var key: String { rawValue }
    }
}
