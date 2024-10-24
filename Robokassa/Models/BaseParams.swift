import Foundation

protocol BaseParams {
    var merchantLogin: String { get }
    var password1: String { get }
    var password2: String { get }
}

protocol Params {
    func checkRequiredFields()
}
