import Foundation

struct Invoice: Decodable {
    let invoiceID: String
    let errorCode: Int
    let errorMessage: String?
}
