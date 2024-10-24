import Foundation

public enum Constants {
    static let FORM_URL_ENCODED = "application/x-www-form-urlencoded"
    static let main = "https://auth.robokassa.ru/Merchant/Indexjson.aspx"
    static let simplePayment = "https://auth.robokassa.ru/Merchant/Index/"
    static let holdingConfirm = "https://auth.robokassa.ru/Merchant/Payment/Confirm"
    static let holdingCancel = "https://auth.robokassa.ru/Merchant/Payment/Cancel"
    static let recurringPayment = "https://auth.robokassa.ru/Merchant/Recurring"
    static let checkPayment = "https://auth.robokassa.ru/Merchant/WebService/Service.asmx/OpStateExt"
}
