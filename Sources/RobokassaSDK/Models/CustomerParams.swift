import Foundation

public struct CustomerParams: Codable {
    public var culture: Culture?
    public var email: String?
    public var ip: String?
    
    public init(culture: Culture? = nil, email: String? = nil, ip: String? = nil) {
        self.culture = culture
        self.email = email
        self.ip = ip
    }
}
