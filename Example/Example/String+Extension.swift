import Foundation

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool { (self ?? "").isEmpty }
}
