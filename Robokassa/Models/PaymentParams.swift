import Foundation
import CryptoKit

public struct PaymentParams: BaseParams, Codable {
    public var merchantLogin: String = ""
    public var password1: String = ""
    public var password2: String = ""
    
    // Order information
    public var order: OrderParams

    // Customer information
    public var customer: CustomerParams

    // View parameters for payment page appearance
    public var view: ViewParams
    
    public init(order: OrderParams, customer: CustomerParams, view: ViewParams) {
        self.order = order
        self.customer = customer
        self.view = view
    }
}

public extension PaymentParams {
    var checkPaymentParams: String {
        var result = "MerchantLogin=\(merchantLogin)"
        var signature = merchantLogin
        
        if order.invoiceId > 0 {
            let id = String(order.invoiceId)
            result += "&invoiceID=\(id)"
            signature += ":\(id)"
        } else {
            signature += ":"
        }
        
        signature += ":\(password2)"
        
        let signatureValue = md5Hash(signature)
        result += "&Signature=\(signatureValue)"
        
        return result
    }
    
    var confirmHoldingParams: String {
        var result = "MerchantLogin=\(merchantLogin)"
        var signature = merchantLogin
        
        // Order Sum
        if order.orderSum > 0 {
            let outSum = String(order.orderSum)
            result += "&OutSum=\(outSum)"
            signature += ":\(outSum)"
        }
        
        // Invoice ID
        if order.invoiceId > 0 {
            let id = String(order.invoiceId)
            result += "&invoiceID=\(id)"
            signature += ":\(id)"
        } else {
            signature += ":"
        }
        
        // Receipt
        if let receipt = order.receipt {
            if let jsonData = try? JSONEncoder().encode(receipt),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let jsonEncoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    result += "&Receipt=\(jsonEncoded)"
                    signature += ":\(jsonString)"
                }
            }
        }
        
        signature += ":\(password1)"
        
        let signatureValue = md5Hash(signature)
        result += "&SignatureValue=\(signatureValue)"
        
        return result
    }
    
    var cancelHoldingParams: String {
        var result = "MerchantLogin=\(merchantLogin)"
        var signature = merchantLogin
        
        // Order Sum
        if order.orderSum > 0 {
            let outSum = String(order.orderSum)
            result += "&OutSum=\(outSum)"
        }
        
        // Invoice ID
        if order.invoiceId > 0 {
            let id = String(order.invoiceId)
            result += "&invoiceID=\(id)"
            signature += "::\(id)"
        } else {
            signature += "::"
        }
        
        signature += ":\(password1)"
        
        let signatureValue = md5Hash(signature)
        result += "&SignatureValue=\(signatureValue)"
        
        return result
    }
    
    var recurrentPostParams: String {
        var result = "MerchantLogin=\(merchantLogin)"
        var signature = merchantLogin
        
        // Order Sum
        if order.orderSum > 0 {
            let outSum = String(order.orderSum)
            result += "&OutSum=\(outSum)"
            signature += ":\(outSum)"
        }
        
        // Invoice ID
        if order.invoiceId > 0 {
            let id = String(order.invoiceId)
            result += "&invoiceID=\(id)"
            signature += ":\(id)"
        } else {
            signature += ":"
        }
        
        if order.previousInvoiceId > 0 {
            result += "&PreviousInvoiceID=\(order.previousInvoiceId)"
        }
        
        // Receipt
        if let receipt = order.receipt {
            if let jsonData = try? JSONEncoder().encode(receipt),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let jsonEncoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    result += "&Receipt=\(jsonEncoded)"
                    signature += ":\(jsonString)"
                }
            }
        }
        
        signature += ":\(password1)"
        
        let signatureValue = md5Hash(signature)
        result += "&SignatureValue=\(signatureValue)"
        
        return result
    }
    
    func payPostParams(isTest: Bool) -> String {
        var result = "MerchantLogin=\(merchantLogin)"
        var signature = merchantLogin
        
        // Description
        if let description = order.description, !description.isEmpty {
            result += "&Description=\(description)"
        }
        
        // Order Sum
        if order.orderSum > 0 {
            let outSum = String(order.orderSum)
            result += "&OutSum=\(outSum)"
            signature += ":\(outSum)"
        }
        
        // Invoice ID
        if order.invoiceId > 0 {
            let id = String(order.invoiceId)
            result += "&invoiceID=\(id)"
            signature += ":\(id)"
        } else {
            signature += ":"
        }
        
        // Receipt
        if let receipt = order.receipt {
            if let jsonData = try? JSONEncoder().encode(receipt),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let jsonEncoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    result += "&Receipt=\(jsonEncoded)"
                    signature += ":\(jsonString)"
                }
            }
        }
        
        // Hold
        if order.isHold {
            result += "&StepByStep=true"
            signature += ":true"
        }
        
        // Recurrent
        if order.isRecurrent {
            result += "&Recurring=true"
        }
        
        // Expiration Date
        if let expirationDate = order.expirationDate {
            result += "&ExpirationDate=\(expirationDate.isoString)"
        }
        
        // Currency Label
        if let incCurrLabel = order.incCurrLabel, !incCurrLabel.isEmpty {
            result += "&IncCurrLabel=\(incCurrLabel)"
        }
        
        if let token = order.token, !token.isEmpty {
            result += "&Token=\(token)"
            signature += ":\(token)"
        }
        
        // Culture
        if let culture = customer.culture {
            result += "&Culture=\(culture.iso)"
        }
        
        // Email
        if let email = customer.email, !email.isEmpty {
            result += "&Email=\(email)"
        }
        
        // User IP
        if let ip = customer.ip, !ip.isEmpty {
            result += "&UserIp=\(ip)"
            signature += ":\(ip)"
        }
        
        // Test Mode
        if isTest {
            result += "&IsTest=1"
        }
        
        signature += ":\(password1)"
        
        let signatureValue = md5Hash(signature)
        result += "&SignatureValue=\(signatureValue)"
        
        return result
    }
    
    // Helper function to generate MD5 hash
    private func md5Hash(_ string: String) -> String {
        // Convert the string to data
        let data = Data(string.utf8)
        
        // Create MD5 hash
        let digest = Insecure.MD5.hash(data: data)
        
        // Convert the hash to a hex string
        return digest.map { String(format: "%02x", $0) }.joined()

    }
}
