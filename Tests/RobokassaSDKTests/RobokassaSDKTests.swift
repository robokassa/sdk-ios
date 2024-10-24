import XCTest
@testable import RobokassaSDK

final class RobokassaSDKTests: XCTestCase {
    func testExample() throws {
        let login = "1234"
        let password = "1234"
        let text = "LOGIN: \(login)\nPASSWORD: \(password)"
        let robokassa = Robokassa(invoiceId: "1234", login: login, password: password, password2: password)
        XCTAssertEqual(robokassa.password, text)
    }
}
